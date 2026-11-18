#!/usr/bin/env bash
# AIGate — capture one agent session and emit its manifest.
#
# The lab (namespace + veth + NAT) must already be up, created with
# `lab_session.sh up`. This script:
#
#   1. starts tcpdump on the host side of the veth,
#   2. copies the fixture workspace into data/work/<session_id>/,
#   3. runs the given command inside the namespace,
#   4. stops the capture, verifies the PCAP, computes hashes and writes
#      data/raw/<session_id>/capture.meta.json and
#      data/manifests/<session_id>.yaml.
#
# It does not create or destroy the network namespace, does not authenticate
# clients and does not interpret the task result. The manifest is emitted with
# `valid: false` and `invalidation_reason: "pending-review"` until manual review.
#
# Requires root (tcpdump on a raw interface).
#
# Usage:
#   sudo scripts/capture_session.sh --lab-id s01 --agent openai --family F2 \
#       --repetition 1 --phase pilot --prompt fixtures/prompts/f2.txt \
#       -- <client command...>
#
# The command after `--` runs inside the namespace with the fixture workspace
# as working directory. Build it with the client's own non-interactive flags;
# the prompt is intentionally not interpreted by this script.
#
# DRY_RUN=1 prints the planned actions without starting tcpdump or creating
# files (it still reads the lab state file when present).

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="${0##*/}"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly STATE_DIR="${AIGATE_STATE_DIR:-/run/aigate-lab}"
readonly RAW_ROOT="$REPO_ROOT/data/raw"
readonly MANIFEST_DIR="$REPO_ROOT/data/manifests"
readonly WORK_ROOT="$REPO_ROOT/data/work"
readonly DNS_RESOLVER="1.1.1.1"
readonly LABELLING_RULES_VERSION=1
readonly DEFAULT_MAX_DURATION=900
readonly DEFAULT_IDLE_TIMEOUT=120
readonly DEFAULT_MAX_BYTES=536870912
readonly PYTHON_BIN="${AIGATE_PYTHON:-$REPO_ROOT/.venv/bin/python}"

log() { printf '[capture] %s\n' "$*" >&2; }
die() { printf '[capture] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
    cat >&2 <<EOF
Usage:
  sudo $SCRIPT_NAME --lab-id <id> --agent <provider> --family <F1|F2|F3> \\
       --repetition <1-3> [options] -- <client command...>

Required:
  --lab-id <id>            Lab created by lab_session.sh (1-8 chars).
  --agent <provider>       openai | anthropic | deepseek.
  --family <family>        F1 | F2 | F3.
  --repetition <n>         1-3.

Options:
  --phase <phase>          pilot (default) | main.
  --prompt <file>          Prompt file; only its SHA-256 is recorded.
  --fixture <path>         Fixture file or directory (defaults by family).
  --fixture-id <id>        Fixture identifier (defaults by family).
  --model-requested <id>   Model requested by the operator (default: default).
  --model-reported <id>    Model reported by the client, if known.
  --client-version <v>     Override the detected client version.
  --auth-mode <mode>       chatgpt_subscription | oauth_subscription | api_key | unknown.
  --plan <label>           Free-form plan label; avoid personal data.
  --telemetry-disabled <v> true | false | unknown (default: unknown).
  --autoupdate-disabled <v> true | false | unknown (default: unknown).
  --standalone <v>         true | false | not_applicable.
  --session-label <label>  Session label (default: AGENT_ASSOCIATED_SESSION).
  --operator <name>        Default: local.
  --max-duration <s>       Hard timeout (default: $DEFAULT_MAX_DURATION).
  --idle-timeout <s>       Stop after no PCAP growth (default: $DEFAULT_IDLE_TIMEOUT, 0 disables).
  --max-bytes <n>          Stop when the PCAP exceeds n bytes (default: $DEFAULT_MAX_BYTES).
  --no-workspace           Do not copy fixtures/workspace into data/work/.
  --force                  Allow reusing an existing session_id (destructive).

Environment:
  DRY_RUN=1                Print the plan without executing it.
  AIGATE_STATE_DIR         Lab state directory (default: /run/aigate-lab).
  AIGATE_PYTHON            Python interpreter used to write the manifest.
EOF
    exit 2
}

require_root() {
    if [[ ${DRY_RUN:-0} == 1 ]]; then
        log "dry-run: skipping root check"
        return 0
    fi
    [[ ${EUID:-0} -eq 0 ]] || die "must run as root (use sudo)"
}

require_tools() {
    local tool
    for tool in ip tcpdump sha256sum timeout; do
        command -v "$tool" >/dev/null 2>&1 || die "missing tool: $tool"
    done
    [[ -x "$PYTHON_BIN" ]] || die "python not found at $PYTHON_BIN"
}

valid_lab_id() { [[ "$1" =~ ^[a-z0-9]{1,8}$ ]]; }

state_file() { printf '%s/%s.env' "$STATE_DIR" "$1"; }

# shellcheck disable=SC1090
load_state() {
    local file
    file="$(state_file "$1")"
    [[ -f "$file" ]] || return 1
    . "$file"
}

need_value() {
    [[ $# -ge 2 && -n ${2:-} ]] || die "missing value for $1"
}

sha256_file() { sha256sum "$1" | awk '{print $1}'; }

# Deterministic hash of a directory tree (relative paths, no bytecode).
sha256_tree() {
    local dir="$1"
    (
        cd "$dir"
        find . -type f ! -path './__pycache__/*' ! -path '*/__pycache__/*' -print0 \
            | sort -z \
            | xargs -0 -r sha256sum \
            | sha256sum \
            | awk '{print $1}'
    )
}

detect_client_version() {
    local agent="$1" bin="$2" raw=""
    raw="$("$bin" --version 2>/dev/null || true)"
    case "$agent" in
        openai) awk '{print $2; exit}' <<<"$raw" ;;
        anthropic) awk '{print $1; exit}' <<<"$raw" ;;
        deepseek) awk '{print $2; exit}' <<<"$raw" | sed 's/^v//' ;;
    esac
}

validate_enum() {
    local name="$1" value="$2"
    shift 2
    local allowed
    for allowed in "$@"; do
        [[ "$value" == "$allowed" ]] && return 0
    done
    die "$name must be one of: $*"
}

cleanup() {
    local code=$?
    trap - EXIT INT TERM
    if [[ -n ${WATCHDOG_PID:-} ]] && kill -0 "$WATCHDOG_PID" 2>/dev/null; then
        kill "$WATCHDOG_PID" 2>/dev/null || true
        wait "$WATCHDOG_PID" 2>/dev/null || true
    fi
    if [[ -n ${CLIENT_PID:-} ]] && kill -0 "$CLIENT_PID" 2>/dev/null; then
        kill -TERM "$CLIENT_PID" 2>/dev/null || true
        sleep 2
        kill -KILL "$CLIENT_PID" 2>/dev/null || true
    fi
    if [[ -n ${TCPDUMP_PID:-} ]] && kill -0 "$TCPDUMP_PID" 2>/dev/null; then
        kill -INT "$TCPDUMP_PID" 2>/dev/null || true
        wait "$TCPDUMP_PID" 2>/dev/null || true
    fi
    exit "$code"
}

main() {
    local agent="" family="" repetition="" lab_id="" phase="pilot"
    local prompt="" fixture="" fixture_id="" model_requested="default"
    local model_reported="" client_version="" auth_mode="unknown" plan=""
    local telemetry="unknown" autoupdate="unknown" standalone=""
    local session_label="AGENT_ASSOCIATED_SESSION" operator="local"
    local max_duration="$DEFAULT_MAX_DURATION"
    local idle_timeout="$DEFAULT_IDLE_TIMEOUT"
    local max_bytes="$DEFAULT_MAX_BYTES"
    local copy_workspace=1 force=0

    while (($#)); do
        case "$1" in
            --agent) need_value "$@"; agent="$2"; shift 2 ;;
            --family) need_value "$@"; family="$2"; shift 2 ;;
            --repetition) need_value "$@"; repetition="$2"; shift 2 ;;
            --lab-id) need_value "$@"; lab_id="$2"; shift 2 ;;
            --phase) need_value "$@"; phase="$2"; shift 2 ;;
            --prompt) need_value "$@"; prompt="$2"; shift 2 ;;
            --fixture) need_value "$@"; fixture="$2"; shift 2 ;;
            --fixture-id) need_value "$@"; fixture_id="$2"; shift 2 ;;
            --model-requested) need_value "$@"; model_requested="$2"; shift 2 ;;
            --model-reported) need_value "$@"; model_reported="$2"; shift 2 ;;
            --client-version) need_value "$@"; client_version="$2"; shift 2 ;;
            --auth-mode) need_value "$@"; auth_mode="$2"; shift 2 ;;
            --plan) need_value "$@"; plan="$2"; shift 2 ;;
            --telemetry-disabled) need_value "$@"; telemetry="$2"; shift 2 ;;
            --autoupdate-disabled) need_value "$@"; autoupdate="$2"; shift 2 ;;
            --standalone) need_value "$@"; standalone="$2"; shift 2 ;;
            --session-label) need_value "$@"; session_label="$2"; shift 2 ;;
            --operator) need_value "$@"; operator="$2"; shift 2 ;;
            --max-duration) need_value "$@"; max_duration="$2"; shift 2 ;;
            --idle-timeout) need_value "$@"; idle_timeout="$2"; shift 2 ;;
            --max-bytes) need_value "$@"; max_bytes="$2"; shift 2 ;;
            --no-workspace) copy_workspace=0; shift ;;
            --force) force=1; shift ;;
            -h|--help|help) usage ;;
            --) shift; break ;;
            *) die "unknown option: $1" ;;
        esac
    done

    (($# > 0)) || usage

    require_root
    require_tools

    [[ -n "$lab_id" ]] || die "--lab-id is required"
    valid_lab_id "$lab_id" || die "lab_id must match ^[a-z0-9]{1,8}$"
    [[ -n "$agent" ]] || die "--agent is required"
    validate_enum "--agent" "$agent" openai anthropic deepseek
    [[ -n "$family" ]] || die "--family is required"
    validate_enum "--family" "$family" F1 F2 F3
    [[ "$repetition" =~ ^[1-3]$ ]] || die "--repetition must be 1, 2 or 3"
    validate_enum "--phase" "$phase" pilot main
    validate_enum "--auth-mode" "$auth_mode" \
        chatgpt_subscription oauth_subscription api_key unknown
    validate_enum "--telemetry-disabled" "$telemetry" true false unknown
    validate_enum "--autoupdate-disabled" "$autoupdate" true false unknown
    validate_enum "--session-label" "$session_label" \
        AGENT_ASSOCIATED_SESSION NON_AGENT_REFERENCE_SESSION AUTOMATION_NON_AI \
        HUMAN_REFERENCE BACKGROUND_NOISE CLIENT_RUNTIME_IDLE
    [[ "$max_duration" =~ ^[0-9]+$ ]] || die "--max-duration must be an integer"
    [[ "$idle_timeout" =~ ^[0-9]+$ ]] || die "--idle-timeout must be an integer"
    [[ "$max_bytes" =~ ^[0-9]+$ ]] || die "--max-bytes must be an integer"
    (( max_duration > 0 )) || die "--max-duration must be greater than 0"
    if [[ "$session_label" == "AGENT_ASSOCIATED_SESSION" && -z "$prompt" ]]; then
        die "positive sessions need --prompt; use a negative label for controls"
    fi

    local client short_name bin
    case "$agent" in
        openai)
            client="codex-cli"; short_name="openai-codex"; bin="codex"
            ;;
        anthropic)
            client="claude-code"; short_name="anthropic-claude"; bin="claude"
            ;;
        deepseek)
            client="opencode"; short_name="deepseek-opencode"; bin="opencode"
            ;;
    esac

    if [[ -z "$client_version" ]]; then
        client_version="$(detect_client_version "$agent" "$bin")"
    fi
    [[ -n "$client_version" ]] || die "cannot detect $bin version; use --client-version"
    [[ -n "$standalone" ]] || {
        if [[ "$agent" == deepseek ]]; then standalone="true"; else standalone="not_applicable"; fi
    }
    validate_enum "--standalone" "$standalone" true false not_applicable

    local prompt_abs="" prompt_sha=""
    if [[ -n "$prompt" ]]; then
        prompt_abs="$(realpath -e "$prompt" 2>/dev/null)" || die "prompt not found: $prompt"
        prompt_sha="$(sha256_file "$prompt_abs")"
    fi

    if [[ -z "$fixture" ]]; then
        if [[ "$family" == F3 ]]; then
            fixture="$REPO_ROOT/fixtures/fixture_server.py"
            [[ -n "$fixture_id" ]] || fixture_id="aigate-fixture-server-v1"
        else
            fixture="$REPO_ROOT/fixtures/workspace"
            [[ -n "$fixture_id" ]] || fixture_id="aigate-workspace-v1"
        fi
    fi
    local fixture_abs fixture_sha=""
    fixture_abs="$(realpath -e "$fixture" 2>/dev/null)" || die "fixture not found: $fixture"
    if [[ -d "$fixture_abs" ]]; then
        fixture_sha="$(sha256_tree "$fixture_abs")"
    else
        fixture_sha="$(sha256_file "$fixture_abs")"
    fi

    local ns vh vn host_ip ns_ip
    if load_state "$lab_id"; then
        ns="$NS"; vh="$VH"; vn="$VN"; host_ip="$HOST_IP"; ns_ip="$NS_IP"
    else
        [[ ${DRY_RUN:-0} == 1 ]] \
            || die "lab '$lab_id' is not up (no state in $STATE_DIR)"
        ns="aigate-$lab_id"; vh="veth-h-$lab_id"; vn="veth-n-$lab_id"
        host_ip="10.203.1.1"; ns_ip="10.203.1.2"
        log "dry-run: no state file; assuming subnet index 1"
    fi

    if [[ ${DRY_RUN:-0} != 1 ]]; then
        ip netns list | awk '{print $1}' | grep -qx "$ns" \
            || die "namespace '$ns' is not up"
        ip link show "$vh" >/dev/null 2>&1 \
            || die "interface '$vh' not found"
    fi

    if [[ "$family" == F3 && "$host_ip" != "10.203.1.1" ]]; then
        die "F3 hardcodes http://10.203.1.1:8080 in the prompt; use subnet index 1"
    fi

    local ts session_id
    ts="$(date -u +%Y%m%dT%H%M%SZ)"
    session_id="${ts}-${short_name}-${family,,}-r${repetition}"

    local raw_dir="$RAW_ROOT/$session_id"
    local work_dir="$WORK_ROOT/$session_id"
    local manifest_path="$MANIFEST_DIR/$session_id.yaml"
    local pcap="$raw_dir/session.pcap"

    if (( ! force )); then
        [[ ! -e "$raw_dir" ]] || die "raw directory already exists: $raw_dir"
        [[ ! -e "$work_dir" ]] || die "work directory already exists: $work_dir"
        [[ ! -e "$manifest_path" ]] || die "manifest already exists: $manifest_path"
    fi

    local mtu zeek_version tcpdump_version host_os started_epoch started_at
    mtu="$(ip -o link show dev "$vh" 2>/dev/null \
        | sed -n 's/.* mtu \([0-9][0-9]*\).*/\1/p' || true)"
    [[ -n "$mtu" ]] || mtu="1500"
    zeek_version="$(zeek --version 2>/dev/null | awk '{print $3; exit}' || true)"
    [[ -n "$zeek_version" ]] || zeek_version="unknown"
    tcpdump_version="$(tcpdump --version 2>/dev/null \
        | sed -n 's/^tcpdump version \([^ ]*\).*/\1/p' | head -n1 || true)"
    [[ -n "$tcpdump_version" ]] || tcpdump_version="unknown"
    host_os="$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-Linux}")"

    if [[ ${DRY_RUN:-0} == 1 ]]; then
        printf '[capture] dry-run plan\n' >&2
        printf '  session_id     : %s\n' "$session_id" >&2
        printf '  lab            : %s (%s -> %s)\n' "$ns" "$ns_ip" "$host_ip" >&2
        printf '  capture iface  : %s\n' "$vh" >&2
        printf '  pcap           : %s\n' "$pcap" >&2
        printf '  workdir        : %s\n' "$work_dir" >&2
        printf '  manifest       : %s\n' "$manifest_path" >&2
        printf '  agent/client   : %s / %s %s\n' "$agent" "$client" "$client_version" >&2
        printf '  family/repetition: %s / %s\n' "$family" "$repetition" >&2
        printf '  prompt sha256  : %s\n' "${prompt_sha:-none}" >&2
        printf '  fixture        : %s (%s)\n' "$fixture_abs" "$fixture_sha" >&2
        printf '  command        :' >&2
        printf ' %q' "$@" >&2
        printf '\n' >&2
        printf '[dry-run] tcpdump -i %q -n -s 0 --time-stamp-precision=nano -w %q\n' \
            "$vh" "$pcap" >&2
        printf '[dry-run] (cd %q && ip netns exec %q timeout %s ...)\n' \
            "$work_dir" "$ns" "$max_duration" >&2
        return 0
    fi

    mkdir -p "$RAW_ROOT" "$MANIFEST_DIR" "$WORK_ROOT"
    mkdir -p "$raw_dir"
    chmod 0700 "$raw_dir"
    mkdir -p "$work_dir"
    if (( copy_workspace )); then
        cp -a "$REPO_ROOT/fixtures/workspace/." "$work_dir/"
    fi

    trap cleanup EXIT INT TERM

    started_epoch="$(date +%s.%N)"
    started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    log "starting tcpdump on $vh"
    tcpdump -i "$vh" -n -s 0 --time-stamp-precision=nano -w "$pcap" \
        >"$raw_dir/tcpdump.stdout" 2>"$raw_dir/tcpdump.log" &
    TCPDUMP_PID=$!
    sleep 1
    if ! kill -0 "$TCPDUMP_PID" 2>/dev/null; then
        die "tcpdump exited early; see $raw_dir/tcpdump.log"
    fi

    log "running command inside $ns (timeout ${max_duration}s, idle ${idle_timeout}s)"
    (
        cd "$work_dir"
        exec ip netns exec "$ns" env \
            -u http_proxy -u https_proxy -u all_proxy \
            -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
            timeout --signal=TERM --kill-after=30 "$max_duration" "$@"
    ) >"$raw_dir/command.stdout" 2>"$raw_dir/command.stderr" &
    CLIENT_PID=$!

    # Watchdog: stop on PCAP growth limits. The main process waits for the
    # client and then terminates the watchdog.
    (
        last=0
        idle=0
        stop_capture() {
            printf '%s\n' "$1" >"$raw_dir/stop_reason"
            kill -TERM "$CLIENT_PID" 2>/dev/null || true
            sleep 10
            kill -KILL "$CLIENT_PID" 2>/dev/null || true
        }
        while kill -0 "$CLIENT_PID" 2>/dev/null; do
            sleep 5
            kill -0 "$CLIENT_PID" 2>/dev/null || break
            if ! kill -0 "$TCPDUMP_PID" 2>/dev/null; then
                stop_capture "tcpdump_died"
                exit 0
            fi
            size="$(stat -c%s "$pcap" 2>/dev/null || printf '0')"
            if (( max_bytes > 0 && size > max_bytes )); then
                stop_capture "size_limit"
                exit 0
            fi
            if (( size == last )); then
                idle=$((idle + 5))
            else
                idle=0
                last="$size"
            fi
            if (( idle_timeout > 0 && idle >= idle_timeout )); then
                stop_capture "idle_timeout"
                exit 0
            fi
        done
    ) &
    WATCHDOG_PID=$!

    local rc=0
    set +e
    wait "$CLIENT_PID"
    rc=$?
    set -e
    CLIENT_PID=""

    kill "$WATCHDOG_PID" 2>/dev/null || true
    wait "$WATCHDOG_PID" 2>/dev/null || true
    WATCHDOG_PID=""

    log "client exited with code $rc; stopping tcpdump"
    if kill -0 "$TCPDUMP_PID" 2>/dev/null; then
        kill -INT "$TCPDUMP_PID" 2>/dev/null || true
    fi
    set +e
    wait "$TCPDUMP_PID"
    set -e
    TCPDUMP_PID=""

    local ended_epoch ended_at duration stop_reason timeout_hit success
    ended_epoch="$(date +%s.%N)"
    ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    duration="$(awk -v a="$started_epoch" -v b="$ended_epoch" 'BEGIN { printf "%.3f", b - a }')"
    stop_reason=""
    if [[ -f "$raw_dir/stop_reason" ]]; then
        stop_reason="$(tr -d '\n' <"$raw_dir/stop_reason")"
    fi
    timeout_hit=0
    if [[ -n "$stop_reason" || "$rc" -eq 124 ]]; then
        timeout_hit=1
    fi
    success=0
    if [[ "$rc" -eq 0 && "$timeout_hit" -eq 0 ]]; then
        success=1
    fi

    local packets dropped bytes pcap_sha pcap_ok=0
    packets="$(sed -n 's/^\([0-9][0-9]*\) packets captured$/\1/p' \
        "$raw_dir/tcpdump.log" | tail -n1)"
    dropped="$(sed -n 's/^\([0-9][0-9]*\) packets dropped by kernel$/\1/p' \
        "$raw_dir/tcpdump.log" | tail -n1)"
    bytes="$(stat -c%s "$pcap" 2>/dev/null || printf '0')"
    pcap_sha="$(sha256_file "$pcap" 2>/dev/null || true)"
    if [[ -s "$pcap" ]] && tcpdump -r "$pcap" -c 1 -nn >/dev/null 2>&1; then
        pcap_ok=1
    fi

    local command_sha
    command_sha="$(printf '%s\0' "$@" | sha256sum | awk '{print $1}')"

    log "writing manifest and capture metadata"
    AIGATE_SESSION_ID="$session_id" \
    AIGATE_PHASE="$phase" \
    AIGATE_OPERATOR="$operator" \
    AIGATE_FAMILY="$family" \
    AIGATE_REPETITION="$repetition" \
    AIGATE_PROMPT_SHA="$prompt_sha" \
    AIGATE_FIXTURE_ID="$fixture_id" \
    AIGATE_FIXTURE_SHA="$fixture_sha" \
    AIGATE_AGENT="$agent" \
    AIGATE_CLIENT="$client" \
    AIGATE_CLIENT_VERSION="$client_version" \
    AIGATE_MODEL_REQUESTED="$model_requested" \
    AIGATE_MODEL_REPORTED="$model_reported" \
    AIGATE_AUTH_MODE="$auth_mode" \
    AIGATE_PLAN="$plan" \
    AIGATE_HOST_OS="$host_os" \
    AIGATE_KERNEL="$(uname -r)" \
    AIGATE_ARCH="$(uname -m)" \
    AIGATE_ZEEK_VERSION="$zeek_version" \
    AIGATE_TCPDUMP_VERSION="$tcpdump_version" \
    AIGATE_NETNS="$ns" \
    AIGATE_VETH_HOST="$vh" \
    AIGATE_VETH_NS="$vn" \
    AIGATE_HOST_IP="$host_ip/30" \
    AIGATE_NS_IP="$ns_ip/30" \
    AIGATE_MTU="$mtu" \
    AIGATE_PCAP_FILE="data/raw/$session_id/session.pcap" \
    AIGATE_PCAP_SHA="$pcap_sha" \
    AIGATE_STARTED_AT="$started_at" \
    AIGATE_ENDED_AT="$ended_at" \
    AIGATE_PACKETS="$packets" \
    AIGATE_BYTES="$bytes" \
    AIGATE_ZEEK_LOGDIR="data/processed/$session_id/zeek" \
    AIGATE_EXIT_CODE="$rc" \
    AIGATE_STARTED_EPOCH="$started_epoch" \
    AIGATE_ENDED_EPOCH="$ended_epoch" \
    AIGATE_DURATION="$duration" \
    AIGATE_TIMEOUT_HIT="$timeout_hit" \
    AIGATE_SUCCESS="$success" \
    AIGATE_TELEMETRY="$telemetry" \
    AIGATE_AUTOUPDATE="$autoupdate" \
    AIGATE_STANDALONE="$standalone" \
    AIGATE_SESSION_LABEL="$session_label" \
    AIGATE_LABELLING_RULES_VERSION="$LABELLING_RULES_VERSION" \
    AIGATE_STOP_REASON="$stop_reason" \
    AIGATE_DROPPED="$dropped" \
    AIGATE_PCAP_OK="$pcap_ok" \
    AIGATE_COMMAND_SHA="$command_sha" \
    AIGATE_WORKDIR="data/work/$session_id" \
    PYTHONPATH="$REPO_ROOT/src${PYTHONPATH:+:$PYTHONPATH}" \
    "$PYTHON_BIN" "$REPO_ROOT/scripts/_write_capture_manifest.py" \
        "$raw_dir/capture.meta.json" "$manifest_path" \
        || die "failed to write or validate the manifest"

    log "session $session_id captured"
    printf 'pcap      : data/raw/%s/session.pcap (%s packets, %s bytes)\n' \
        "$session_id" "${packets:-?}" "$bytes"
    printf 'sha256    : %s\n' "${pcap_sha:-unavailable}"
    printf 'exit code : %s (timeout_hit=%s, stop_reason=%s)\n' \
        "$rc" "$timeout_hit" "${stop_reason:-none}"
    printf 'manifest  : %s\n' "$manifest_path"
    printf 'valid     : false (pending human review)\n'

    if (( ! pcap_ok )); then
        die "PCAP is missing or unreadable: $pcap"
    fi
}

main "$@"

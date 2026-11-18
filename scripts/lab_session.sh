#!/usr/bin/env bash
# AIGate — isolated lab network for one capture session.
#
# Creates a network namespace connected to the host through a veth pair, with
# per-namespace DNS, IPv6 disabled inside the namespace and a scoped nftables
# NAT table. All changes are reverted by `down`, including ip_forward.
#
# Requires root. One lab at a time: the nftables table is global.
#
# Usage:
#   sudo scripts/lab_session.sh up   <lab_id> [subnet_index]
#   sudo scripts/lab_session.sh status <lab_id>
#   sudo scripts/lab_session.sh exec <lab_id> -- <command...>
#   sudo scripts/lab_session.sh down <lab_id> [--force]
#
# lab_id: 1-8 lowercase alphanumeric characters (interface names max 15).
# subnet_index: 1-254, default 1. Uses 10.203.<index>.1/30 and .2/30.
# DRY_RUN=1 prints the privileged commands without executing them.

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="${0##*/}"
readonly STATE_DIR="${AIGATE_STATE_DIR:-/run/aigate-lab}"
readonly NFT_TABLE="aigate_lab"
readonly DNS_RESOLVER="1.1.1.1"
readonly LAB_PREFIX="10.203"

log() { printf '[lab] %s\n' "$*" >&2; }
die() { printf '[lab] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
    cat >&2 <<EOF
Usage:
  sudo $SCRIPT_NAME up   <lab_id> [subnet_index]
  sudo $SCRIPT_NAME status <lab_id>
  sudo $SCRIPT_NAME exec <lab_id> -- <command...>
  sudo $SCRIPT_NAME down <lab_id> [--force]

lab_id          1-8 lowercase alphanumeric characters.
subnet_index    1-254 (default 1) -> $LAB_PREFIX.<index>.1/30
DRY_RUN=1       print privileged commands without executing them.
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
    for tool in ip nft sysctl; do
        command -v "$tool" >/dev/null 2>&1 || die "missing tool: $tool"
    done
}

valid_lab_id() {
    [[ "$1" =~ ^[a-z0-9]{1,8}$ ]]
}

state_file() { printf '%s/%s.env' "$STATE_DIR" "$1"; }

# shellcheck disable=SC1090
load_state() {
    local file
    file="$(state_file "$1")"
    [[ -f "$file" ]] || die "no state for lab '$1' in $STATE_DIR"
    # The file is written by this script with fixed keys and quoted values.
    . "$file"
}

run() {
    if [[ ${DRY_RUN:-0} == 1 ]]; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

wan_interface() {
    local iface
    iface="$(ip -4 route show default | awk '{print $5; exit}')"
    [[ -n "$iface" ]] || die "no IPv4 default route; refusing to create NAT"
    ip link show "$iface" >/dev/null 2>&1 || die "default interface '$iface' not found"
    printf '%s' "$iface"
}

table_exists() {
    nft list table inet "$NFT_TABLE" >/dev/null 2>&1
}

declare -i CREATED_NS=0 CREATED_VETH=0 CREATED_TABLE=0 FORWARD_SET=0

rollback_partial() {
    local ns="$1" vh="$2"
    set +e
    log "rolling back partial creation"
    if (( CREATED_TABLE )); then
        nft delete table inet "$NFT_TABLE" 2>/dev/null
    fi
    if (( FORWARD_SET )) && [[ -n ${PREV_FORWARD:-} ]]; then
        sysctl -w "net.ipv4.ip_forward=$PREV_FORWARD" >/dev/null 2>&1
    fi
    if (( CREATED_NS )); then
        ip netns del "$ns" 2>/dev/null
    fi
    if (( CREATED_VETH )); then
        ip link del "$vh" 2>/dev/null
    fi
    rm -rf "/etc/netns/$ns" 2>/dev/null
    set -e
}

cmd_up() {
    local lab_id="${1:-}" index="${2:-1}"
    [[ -n "$lab_id" ]] || usage
    valid_lab_id "$lab_id" || die "lab_id must match ^[a-z0-9]{1,8}$"
    [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= 254 )) \
        || die "subnet_index must be an integer 1-254"

    local ns="aigate-$lab_id"
    local vh="veth-h-$lab_id"
    local vn="veth-n-$lab_id"
    local prefix="$LAB_PREFIX.$index.0/30"
    local host_ip="$LAB_PREFIX.$index.1"
    local ns_ip="$LAB_PREFIX.$index.2"
    local wan
    wan="$(wan_interface)"

    ip netns list | awk '{print $1}' | grep -qx "$ns" && die "namespace '$ns' already exists"
    ip link show "$vh" >/dev/null 2>&1 && die "interface '$vh' already exists"
    ip link show "$vn" >/dev/null 2>&1 && die "interface '$vn' already exists"
    table_exists && die "nft table inet $NFT_TABLE already exists; run 'down' first"
    [[ -e "/etc/netns/$ns" ]] && die "/etc/netns/$ns already exists"

    PREV_FORWARD="$(cat /proc/sys/net/ipv4/ip_forward)"
    [[ "$PREV_FORWARD" =~ ^[01]$ ]] || die "unexpected ip_forward value: $PREV_FORWARD"

    if [[ ${DRY_RUN:-0} != 1 ]]; then
        mkdir -p "$STATE_DIR"
        chmod 0700 "$STATE_DIR"
    fi

    trap 'rollback_partial "$ns" "$vh"' ERR

    log "creating namespace $ns ($prefix, WAN $wan)"
    run ip netns add "$ns"; CREATED_NS=1
    run ip link add "$vh" type veth peer name "$vn"; CREATED_VETH=1
    run ip link set "$vn" netns "$ns"
    run ip addr add "$host_ip/30" dev "$vh"
    run ip link set "$vh" up
    run ip netns exec "$ns" ip addr add "$ns_ip/30" dev "$vn"
    run ip netns exec "$ns" ip link set "$vn" up
    run ip netns exec "$ns" ip link set lo up
    run ip netns exec "$ns" ip route add default via "$host_ip"

    run mkdir -p "/etc/netns/$ns"
    if [[ ${DRY_RUN:-0} == 1 ]]; then
        printf '[dry-run] write %s\n' "/etc/netns/$ns/resolv.conf"
    else
        printf 'nameserver %s\n' "$DNS_RESOLVER" >"/etc/netns/$ns/resolv.conf"
    fi
    run ip netns exec "$ns" sysctl -qw net.ipv6.conf.all.disable_ipv6=1
    run ip netns exec "$ns" sysctl -qw net.ipv6.conf.default.disable_ipv6=1

    log "enabling forwarding (previous value: $PREV_FORWARD)"
    run sysctl -qw net.ipv4.ip_forward=1; FORWARD_SET=1

    log "creating scoped NAT table inet $NFT_TABLE"
    run nft add table inet "$NFT_TABLE"; CREATED_TABLE=1
    run nft "add chain inet $NFT_TABLE postrouting { type nat hook postrouting priority srcnat; }"
    run nft add rule inet "$NFT_TABLE" postrouting ip saddr "$prefix" oifname "$wan" masquerade
    run nft "add chain inet $NFT_TABLE forward { type filter hook forward priority filter; policy accept; }"
    run nft add rule inet "$NFT_TABLE" forward ip saddr "$prefix" accept
    run nft add rule inet "$NFT_TABLE" forward ip daddr "$prefix" ct state established,related accept

    if [[ ${DRY_RUN:-0} != 1 ]]; then
        if ! verify_up "$ns" "$vn" "$host_ip" "$ns_ip"; then
            log "verification failed; rolling back"
            rollback_partial "$ns" "$vh"
            exit 1
        fi
        write_state "$lab_id" "$ns" "$vh" "$vn" "$index" "$prefix" \
            "$host_ip" "$ns_ip" "$wan" "$PREV_FORWARD"
        log "lab '$lab_id' ready: $ns ($ns_ip -> $host_ip, WAN $wan)"
        log "next: sudo $SCRIPT_NAME exec $lab_id -- <command>"
    fi
    trap - ERR
}

write_state() {
    local lab_id="$1" ns="$2" vh="$3" vn="$4" index="$5" prefix="$6"
    local host_ip="$7" ns_ip="$8" wan="$9" prev="${10}"
    local file
    file="$(state_file "$lab_id")"
    {
        printf 'LAB_ID=%q\n' "$lab_id"
        printf 'NS=%q\n' "$ns"
        printf 'VH=%q\n' "$vh"
        printf 'VN=%q\n' "$vn"
        printf 'INDEX=%q\n' "$index"
        printf 'PREFIX=%q\n' "$prefix"
        printf 'HOST_IP=%q\n' "$host_ip"
        printf 'NS_IP=%q\n' "$ns_ip"
        printf 'WAN=%q\n' "$wan"
        printf 'PREV_FORWARD=%q\n' "$prev"
        printf 'CREATED_TABLE=1\n'
        printf 'CREATED_AT=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } >"$file"
    chmod 0600 "$file"
}

verify_up() {
    local ns="$1" vn="$2" host_ip="$3" ns_ip="$4"
    if ! ip netns exec "$ns" ip -4 addr show dev "$vn" | grep -q "$ns_ip"; then
        log "ERROR: namespace has no address $ns_ip on $vn"
        return 1
    fi
    if ! ip netns exec "$ns" ip route | grep -q "default via $host_ip"; then
        log "ERROR: namespace has no default route via $host_ip"
        return 1
    fi
    if [[ "$(ip netns exec "$ns" cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" != 1 ]]; then
        log "ERROR: IPv6 is not disabled inside the namespace"
        return 1
    fi
    if ! ip netns exec "$ns" grep -qx "nameserver $DNS_RESOLVER" /etc/resolv.conf; then
        log "ERROR: namespace resolv.conf does not point to $DNS_RESOLVER"
        return 1
    fi
    if ! ip netns exec "$ns" ping -c1 -W1 "$host_ip" >/dev/null 2>&1; then
        log "warning: gateway $host_ip did not answer ICMP (NAT may still work)"
    fi
}

cmd_status() {
    local lab_id="${1:-}"
    [[ -n "$lab_id" ]] || usage
    valid_lab_id "$lab_id" || die "invalid lab_id"

    local ns="aigate-$lab_id"
    local vh="veth-h-$lab_id"

    if [[ -f "$(state_file "$lab_id")" ]]; then
        load_state "$lab_id"
    fi

    printf 'ip_forward: %s\n' "$(cat /proc/sys/net/ipv4/ip_forward)"
    printf 'nft table inet %s: %s\n' "$NFT_TABLE" \
        "$(table_exists && echo present || echo absent)"
    printf 'namespace %s: %s\n' "$ns" \
        "$(ip netns list | awk '{print $1}' | grep -qx "$ns" && echo present || echo absent)"
    printf 'interface %s: %s\n' "$vh" \
        "$(ip link show "$vh" >/dev/null 2>&1 && echo present || echo absent)"

    if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
        echo '--- namespace addresses ---'
        ip netns exec "$ns" ip -4 addr show
        echo '--- namespace routes ---'
        ip netns exec "$ns" ip route
        echo '--- namespace resolv.conf ---'
        ip netns exec "$ns" cat /etc/resolv.conf
        echo '--- ipv6 disabled ---'
        ip netns exec "$ns" cat /proc/sys/net/ipv6/conf/all/disable_ipv6
        echo '--- processes ---'
        ip netns pids "$ns" || true
    fi
}

cmd_exec() {
    local lab_id="${1:-}"
    [[ -n "$lab_id" ]] || usage
    shift || true
    [[ "${1:-}" == "--" ]] && shift
    (($# > 0)) || die "missing command after --"
    valid_lab_id "$lab_id" || die "invalid lab_id"
    load_state "$lab_id"
    ip netns list | awk '{print $1}' | grep -qx "$NS" || die "namespace '$NS' is not up"

    # Clear proxy variables so inherited host configuration cannot redirect traffic.
    exec ip netns exec "$NS" env \
        -u http_proxy -u https_proxy -u all_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
        "$@"
}

cmd_down() {
    local lab_id="${1:-}" force=0
    [[ -n "$lab_id" ]] || usage
    [[ "${2:-}" == "--force" ]] && force=1
    valid_lab_id "$lab_id" || die "invalid lab_id"

    local ns="aigate-$lab_id" vh="veth-h-$lab_id" vn="veth-n-$lab_id"
    local prev_forward="" created_table=0 restored=0

    if [[ -f "$(state_file "$lab_id")" ]]; then
        load_state "$lab_id"
        ns="$NS" vh="$VH" vn="$VN"
        prev_forward="$PREV_FORWARD"
        created_table="$CREATED_TABLE"
    else
        log "no state file for '$lab_id'"
        if (( ! force )); then
            die "refusing to guess ip_forward; re-run with --force to remove only the namespace and veth"
        fi
    fi

    local pids
    pids="$(ip netns pids "$ns" 2>/dev/null || true)"
    if [[ -n "$pids" ]]; then
        if (( force )); then
            log "killing processes in $ns: $pids"
            # shellcheck disable=SC2086
            kill $pids 2>/dev/null || true
            sleep 1
            # shellcheck disable=SC2086
            kill -9 $pids 2>/dev/null || true
        else
            printf 'processes still running in %s:\n%s\n' "$ns" "$pids" >&2
            die "refusing to remove a live namespace; use --force to kill them"
        fi
    fi

    if (( created_table )) || table_exists; then
        log "deleting nft table inet $NFT_TABLE"
        run nft delete table inet "$NFT_TABLE" || log "warning: could not delete nft table"
    fi

    if [[ -n "$prev_forward" ]]; then
        log "restoring ip_forward=$prev_forward"
        run sysctl -qw "net.ipv4.ip_forward=$prev_forward"
        restored=1
    else
        log "warning: ip_forward not restored because there is no state file"
    fi

    if ip netns list | awk '{print $1}' | grep -qx "$ns"; then
        run ip netns del "$ns"
    fi
    if ip link show "$vh" >/dev/null 2>&1; then
        run ip link del "$vh" || true
    fi
    run rm -rf "/etc/netns/$ns"
    if [[ -f "$(state_file "$lab_id")" ]]; then
        rm -f "$(state_file "$lab_id")"
    fi

    if [[ ${DRY_RUN:-0} == 1 ]]; then
        log "dry-run complete; nothing was removed"
        return 0
    fi
    if (( restored )); then
        verify_down "$ns" "$vh" "$prev_forward"
    else
        verify_down "$ns" "$vh"
    fi
    log "lab '$lab_id' removed"
}

verify_down() {
    local ns="$1" vh="$2" expected="${3:-}"
    local failed=0
    ip netns list | awk '{print $1}' | grep -qx "$ns" \
        && { log "ERROR: namespace $ns still present"; failed=1; }
    ip link show "$vh" >/dev/null 2>&1 \
        && { log "ERROR: interface $vh still present"; failed=1; }
    table_exists \
        && { log "ERROR: nft table inet $NFT_TABLE still present"; failed=1; }
    if [[ -n "$expected" ]]; then
        [[ "$(cat /proc/sys/net/ipv4/ip_forward)" == "$expected" ]] \
            || { log "ERROR: ip_forward is not $expected"; failed=1; }
    fi
    (( failed == 0 )) || die "cleanup verification failed"
    log "cleanup verified"
}

main() {
    (($# >= 1)) || usage
    local command="$1"; shift || true
    case "$command" in
        up)
            require_root; require_tools; cmd_up "$@" ;;
        down)
            require_root; require_tools; cmd_down "$@" ;;
        status)
            require_root; cmd_status "$@" ;;
        exec)
            require_root; cmd_exec "$@" ;;
        -h|--help|help)
            usage ;;
        *)
            die "unknown command: $command" ;;
    esac
}

main "$@"

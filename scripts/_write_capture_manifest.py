#!/usr/bin/env python3
"""Write ``capture.meta.json`` and the YAML manifest for one session.

This helper is called by ``scripts/capture_session.sh`` after tcpdump and the
client command have finished. All values arrive as ``AIGATE_*`` environment
variables; the script owns process orchestration, this module owns the
document shape and validation.

Usage::

    python scripts/_write_capture_manifest.py <meta.json> <manifest.yaml>
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

import yaml

from aigate.capture.manifest import validate_manifest


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def env_opt(name: str) -> str | None:
    value = env(name).strip()
    return value or None


def env_int(name: str, default: int | None = None) -> int | None:
    value = env(name).strip()
    if not value:
        return default
    return int(value)


def env_float(name: str, default: float | None = None) -> float | None:
    value = env(name).strip()
    if not value:
        return default
    return float(value)


def tristate(name: str) -> bool | str:
    value = env(name, "unknown").strip().lower()
    if value == "true":
        return True
    if value == "false":
        return False
    if value == "unknown":
        return "unknown"
    raise ValueError(f"{name} must be true, false or unknown; got {value!r}")


def standalone_mode() -> bool | str:
    value = env("AIGATE_STANDALONE", "not_applicable").strip().lower()
    if value == "true":
        return True
    if value == "false":
        return False
    if value == "not_applicable":
        return "not_applicable"
    raise ValueError(f"AIGATE_STANDALONE must be true, false or not_applicable; got {value!r}")


def build_anomalies(
    *,
    pcap_ok: bool,
    packets: int | None,
    dropped: int | None,
    stop_reason: str | None,
    exit_code: int,
    timeout_hit: bool,
) -> list[str]:
    anomalies: list[str] = []
    if not pcap_ok:
        anomalies.append("PCAP missing or unreadable")
    if packets is None:
        anomalies.append("packet count could not be parsed from the tcpdump log")
    elif packets == 0:
        anomalies.append("no packets captured")
    if dropped:
        anomalies.append(f"kernel dropped {dropped} packets")
    if stop_reason:
        anomalies.append(f"capture stopped early: {stop_reason}")
    if timeout_hit and exit_code == 124:
        anomalies.append("client timeout reached")
    if exit_code not in (0, 124):
        anomalies.append(f"client exited with code {exit_code}")
    return anomalies


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: _write_capture_manifest.py <meta.json> <manifest.yaml>", file=sys.stderr)
        return 2

    meta_path = Path(argv[1])
    manifest_path = Path(argv[2])

    packets = env_int("AIGATE_PACKETS")
    dropped = env_int("AIGATE_DROPPED")
    exit_code = env_int("AIGATE_EXIT_CODE", 0) or 0
    pcap_ok = env("AIGATE_PCAP_OK", "0") == "1"
    timeout_hit = env("AIGATE_TIMEOUT_HIT", "0") == "1"
    stop_reason = env_opt("AIGATE_STOP_REASON")

    anomalies = build_anomalies(
        pcap_ok=pcap_ok,
        packets=packets,
        dropped=dropped,
        stop_reason=stop_reason,
        exit_code=exit_code,
        timeout_hit=timeout_hit,
    )

    manifest: dict[str, Any] = {
        "manifest_version": 1,
        "session_id": env("AIGATE_SESSION_ID"),
        "created_at_utc": env("AIGATE_ENDED_AT"),
        "phase": env("AIGATE_PHASE"),
        "operator": env("AIGATE_OPERATOR", "local"),
        "scenario_family": env("AIGATE_FAMILY"),
        "repetition": env_int("AIGATE_REPETITION", 1),
        "task_prompt_sha256": env_opt("AIGATE_PROMPT_SHA"),
        "fixture_id": env_opt("AIGATE_FIXTURE_ID"),
        "fixture_sha256": env_opt("AIGATE_FIXTURE_SHA"),
        "agent_provider": env("AIGATE_AGENT"),
        "agent_client": env("AIGATE_CLIENT"),
        "client_version": env("AIGATE_CLIENT_VERSION"),
        "model_requested": env("AIGATE_MODEL_REQUESTED", "default"),
        "model_reported": env_opt("AIGATE_MODEL_REPORTED"),
        "auth_mode": env("AIGATE_AUTH_MODE", "unknown"),
        "plan": env_opt("AIGATE_PLAN"),
        "host_os": env("AIGATE_HOST_OS", "unknown"),
        "kernel": env("AIGATE_KERNEL", "unknown"),
        "arch": env("AIGATE_ARCH", "unknown"),
        "python_version": env("AIGATE_PYTHON_VERSION", sys.version.split()[0]),
        "zeek_version": env("AIGATE_ZEEK_VERSION", "unknown"),
        "tcpdump_version": env("AIGATE_TCPDUMP_VERSION", "unknown"),
        "netns": env("AIGATE_NETNS"),
        "veth_host": env("AIGATE_VETH_HOST"),
        "veth_ns": env("AIGATE_VETH_NS"),
        "host_ip": env("AIGATE_HOST_IP"),
        "ns_ip": env("AIGATE_NS_IP"),
        "dns_resolver": "1.1.1.1",
        "ipv6_disabled": True,
        "mtu": env_int("AIGATE_MTU", 1500),
        "pcap_file": env("AIGATE_PCAP_FILE"),
        "pcap_sha256": env_opt("AIGATE_PCAP_SHA"),
        "snaplen": 0,
        "bpf_filter": "none",
        "started_at_utc": env("AIGATE_STARTED_AT"),
        "ended_at_utc": env("AIGATE_ENDED_AT"),
        "packets": packets,
        "bytes": env_int("AIGATE_BYTES"),
        "zeek_logdir": env_opt("AIGATE_ZEEK_LOGDIR"),
        "zeek_scripts": "local",
        "logs_sha256": None,
        "exit_code": exit_code,
        "duration_s": env_float("AIGATE_DURATION"),
        "turns": None,
        "timeout_hit": timeout_hit,
        "success": env("AIGATE_SUCCESS", "0") == "1",
        "telemetry_disabled": tristate("AIGATE_TELEMETRY"),
        "autoupdate_disabled": tristate("AIGATE_AUTOUPDATE"),
        "standalone_mode": standalone_mode(),
        "proxy_env_cleared": True,
        "session_label": env("AIGATE_SESSION_LABEL", "AGENT_ASSOCIATED_SESSION"),
        "labelling_rules_version": int(env("AIGATE_LABELLING_RULES_VERSION", "1")),
        "flow_provenance_counts": {},
        "anomalies": anomalies,
        "valid": False,
        "invalidation_reason": "pending-review",
        "contains_credentials": False,
        "publishable": False,
    }

    try:
        validate_manifest(manifest)
    except Exception as exc:  # jsonschema.ValidationError, ValueError, TypeError
        print(f"manifest validation failed: {exc}", file=sys.stderr)
        print(json.dumps(manifest, indent=2, sort_keys=True, ensure_ascii=False), file=sys.stderr)
        return 1

    meta: dict[str, Any] = {
        "session_id": manifest["session_id"],
        "agent_provider": manifest["agent_provider"],
        "agent_client": manifest["agent_client"],
        "client_version": manifest["client_version"],
        "pcap_file": manifest["pcap_file"],
        "pcap_sha256": manifest["pcap_sha256"],
        "pcap_bytes": env_int("AIGATE_BYTES"),
        "bytes_kind": "pcap_file_size",
        "packets": packets,
        "dropped_by_kernel": dropped,
        "snaplen": 0,
        "bpf_filter": "none",
        "timestamp_precision": "nanoseconds",
        "tcpdump_version": manifest["tcpdump_version"],
        "started_at_utc": manifest["started_at_utc"],
        "ended_at_utc": manifest["ended_at_utc"],
        "duration_s": manifest["duration_s"],
        "exit_code": exit_code,
        "timeout_hit": timeout_hit,
        "stop_reason": stop_reason,
        "command_sha256": env_opt("AIGATE_COMMAND_SHA"),
        "working_dir": env_opt("AIGATE_WORKDIR"),
        "pcap_readable": pcap_ok,
        "anomalies": anomalies,
    }

    meta_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    meta_path.write_text(
        json.dumps(meta, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    manifest_path.write_text(
        yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )
    print(f"manifest written: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

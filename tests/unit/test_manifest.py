"""Tests for the versioned session manifest schema."""

from __future__ import annotations

import copy
from typing import Any

import jsonschema
import pytest
import yaml

from aigate.capture.manifest import load_manifest, load_schema, validate_manifest

BASE_MANIFEST: dict[str, Any] = {
    "manifest_version": 1,
    "session_id": "20261120T101500Z-openai-codex-f1-r1",
    "created_at_utc": "2026-11-20T10:15:00Z",
    "phase": "pilot",
    "operator": "local",
    "scenario_family": "F1",
    "repetition": 1,
    "task_prompt_sha256": "a" * 64,
    "fixture_id": None,
    "fixture_sha256": None,
    "agent_provider": "openai",
    "agent_client": "codex-cli",
    "client_version": "0.170.0",
    "model_requested": "default",
    "model_reported": "gpt-6.2-sol",
    "auth_mode": "chatgpt_subscription",
    "plan": "confirmed-by-user",
    "host_os": "Kali Rolling 2026.3",
    "kernel": "7.1.5+kali-amd64",
    "arch": "x86_64",
    "python_version": "3.14.8",
    "zeek_version": "9.0.1",
    "tcpdump_version": "4.99.6",
    "netns": "aigate-s01",
    "veth_host": "veth-h-s01",
    "veth_ns": "veth-n-s01",
    "host_ip": "10.203.1.1/30",
    "ns_ip": "10.203.1.2/30",
    "dns_resolver": "1.1.1.1",
    "ipv6_disabled": True,
    "mtu": 1500,
    "pcap_file": "data/raw/20261120T101500Z-openai-codex-f1-r1/session.pcap",
    "pcap_sha256": None,
    "snaplen": 0,
    "bpf_filter": "none",
    "started_at_utc": "2026-11-20T10:15:03Z",
    "ended_at_utc": "2026-11-20T10:16:41Z",
    "packets": 120,
    "bytes": 34000,
    "zeek_logdir": "data/processed/20261120T101500Z-openai-codex-f1-r1/zeek",
    "zeek_scripts": "local",
    "logs_sha256": None,
    "exit_code": 0,
    "duration_s": 98.0,
    "turns": 3,
    "timeout_hit": False,
    "success": True,
    "telemetry_disabled": True,
    "autoupdate_disabled": True,
    "standalone_mode": "not_applicable",
    "proxy_env_cleared": True,
    "session_label": "AGENT_ASSOCIATED_SESSION",
    "labelling_rules_version": 1,
    "flow_provenance_counts": {"PROVIDER_API": 4, "AGENT_TOOL_MCP": 1},
    "anomalies": [],
    "valid": True,
    "invalidation_reason": None,
    "contains_credentials": False,
    "publishable": False,
}


def test_schema_is_draft_2020_12() -> None:
    assert load_schema()["$schema"] == "https://json-schema.org/draft/2020-12/schema"


def test_valid_manifest_passes() -> None:
    validate_manifest(copy.deepcopy(BASE_MANIFEST))


def test_design_only_manifest_is_schema_valid() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["valid"] = False
    manifest["invalidation_reason"] = "design-only example"
    validate_manifest(manifest)


def test_missing_required_field_is_rejected() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    del manifest["session_id"]
    with pytest.raises(jsonschema.ValidationError):
        validate_manifest(manifest)


def test_unknown_provider_is_rejected() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["agent_provider"] = "unknown-vendor"
    with pytest.raises(jsonschema.ValidationError):
        validate_manifest(manifest)


def test_unknown_session_label_is_rejected() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["session_label"] = "AI_GENERATED"
    with pytest.raises(jsonschema.ValidationError):
        validate_manifest(manifest)


def test_new_idle_label_is_accepted() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["session_label"] = "CLIENT_RUNTIME_IDLE"
    validate_manifest(manifest)


def test_bad_session_id_is_rejected() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["session_id"] = "session-1"
    with pytest.raises(jsonschema.ValidationError):
        validate_manifest(manifest)


def test_negative_flow_count_is_rejected() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["flow_provenance_counts"] = {"PROVIDER_API": -1}
    with pytest.raises(jsonschema.ValidationError):
        validate_manifest(manifest)


def test_credentials_are_never_accepted() -> None:
    manifest = copy.deepcopy(BASE_MANIFEST)
    manifest["contains_credentials"] = True
    with pytest.raises(jsonschema.ValidationError):
        validate_manifest(manifest)


def test_load_manifest_from_yaml(tmp_path) -> None:
    path = tmp_path / "manifest.yaml"
    path.write_text(yaml.safe_dump(BASE_MANIFEST), encoding="utf-8")
    loaded = load_manifest(path)
    assert loaded["session_id"] == BASE_MANIFEST["session_id"]


def test_load_manifest_rejects_non_mapping(tmp_path) -> None:
    path = tmp_path / "manifest.yaml"
    path.write_text("- not-a-mapping\n", encoding="utf-8")
    with pytest.raises(ValueError):
        load_manifest(path)

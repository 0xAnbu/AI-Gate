"""Infrastructure checks for the AIGate repository skeleton."""

from __future__ import annotations

import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

import pytest
import yaml

PROJECT_ROOT = Path(__file__).resolve().parents[2]


def _read(relative_path: str) -> str:
    return (PROJECT_ROOT / relative_path).read_text(encoding="utf-8")


def test_python_version_is_supported() -> None:
    assert sys.version_info >= (3, 14)


def test_pyproject_declares_static_project_metadata() -> None:
    data = tomllib.loads(_read("pyproject.toml"))
    project = data["project"]

    assert project["name"] == "aigate"
    assert project["requires-python"] == ">=3.14"
    assert "dependencies" not in project.get("dynamic", [])
    assert project["dependencies"]
    assert all("==" in dependency for dependency in project["dependencies"])


def test_runtime_and_development_requirements_are_separated() -> None:
    runtime = _read("requirements.txt").lower()
    development = _read("requirements-dev.txt").lower()

    for tool in ("pytest", "ruff", "pre-commit"):
        assert tool not in runtime
        assert tool in development


def test_expected_directories_exist() -> None:
    expected = [
        "config",
        "data/raw",
        "data/processed",
        "data/external",
        "data/interim",
        "data/manifests",
        "docs",
        "models",
        "scripts",
        "src/aigate",
        "tests",
    ]

    missing = [path for path in expected if not (PROJECT_ROOT / path).is_dir()]

    assert missing == []


def test_source_subpackages_are_importable() -> None:
    import aigate
    from aigate import capture, enforcement, features, models, policy

    assert aigate.__name__ == "aigate"
    modules = (capture, enforcement, features, models, policy)
    assert all(module.__name__.startswith("aigate.") for module in modules)


def test_gitignore_protects_sensitive_artifacts() -> None:
    gitignore = _read(".gitignore")
    expected = [
        "data/raw/*",
        "data/processed/*",
        "data/external/*",
        "data/interim/*",
        "data/manifests/*",
        "models/*",
        "*.pcap",
        "*.pcapng",
        ".env",
    ]

    missing = [pattern for pattern in expected if pattern not in gitignore]

    assert missing == []


def test_makefile_defines_required_targets() -> None:
    makefile = _read("Makefile")
    required = ("install:", "lint:", "format:", "test:", "check:")

    missing = [target for target in required if target not in makefile]

    assert missing == []


def test_pre_commit_configuration_includes_quality_gates() -> None:
    config = yaml.safe_load(_read(".pre-commit-config.yaml"))
    hook_ids = {hook["id"] for repository in config["repos"] for hook in repository["hooks"]}

    assert {"ruff", "ruff-format", "pytest"} <= hook_ids


def test_ci_workflow_runs_quality_gates() -> None:
    workflow = _read(".github/workflows/tests.yml")

    for command in ("ruff check", "ruff format --check", "pytest"):
        assert command in workflow


def test_zeek_is_operational_when_installed() -> None:
    zeek = shutil.which("zeek")
    if zeek is None:
        pytest.skip("Zeek no está instalado en este entorno")

    result = subprocess.run(
        [zeek, "--version"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0
    assert "zeek version" in result.stdout.lower()

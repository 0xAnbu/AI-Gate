"""Tests for the local F3 fixture server.

The server is a script under ``fixtures/``, not an installed module, so it is
loaded by path. The tests bind to an ephemeral port on loopback and never touch
the lab network.
"""

from __future__ import annotations

import importlib.util
import json
import threading
import urllib.error
import urllib.request
from collections.abc import Iterator
from pathlib import Path
from types import ModuleType

import pytest

FIXTURE_PATH = Path(__file__).resolve().parents[2] / "fixtures" / "fixture_server.py"


def load_fixture_module() -> ModuleType:
    spec = importlib.util.spec_from_file_location("aigate_fixture_server", FIXTURE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {FIXTURE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture(scope="module")
def fixture_server() -> Iterator[str]:
    module = load_fixture_module()
    server = module.make_server("127.0.0.1", 0)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    host, port = server.server_address[:2]
    try:
        yield f"http://{host}:{port}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


def get_json(url: str) -> tuple[int, dict[str, object]]:
    with urllib.request.urlopen(url, timeout=5) as response:  # noqa: S310 - loopback only
        return response.status, json.loads(response.read().decode("utf-8"))


def test_health_endpoint(fixture_server: str) -> None:
    status, payload = get_json(f"{fixture_server}/health")
    assert status == 200
    assert payload == {"status": "ok"}


def test_data_endpoint_is_deterministic(fixture_server: str) -> None:
    status, payload = get_json(f"{fixture_server}/data")
    assert status == 200
    assert payload["count"] == 6
    readings = payload["readings"]
    assert isinstance(readings, list)
    assert [item["id"] for item in readings] == [1, 2, 3, 4, 5, 6]
    mean = sum(item["value"] for item in readings) / len(readings)
    assert mean == pytest.approx(11.75)


def test_unknown_path_returns_404(fixture_server: str) -> None:
    with pytest.raises(urllib.error.HTTPError) as excinfo:
        urllib.request.urlopen(f"{fixture_server}/missing", timeout=5)  # noqa: S310
    assert excinfo.value.code == 404
    payload = json.loads(excinfo.value.read().decode("utf-8"))
    assert payload["error"] == "not_found"

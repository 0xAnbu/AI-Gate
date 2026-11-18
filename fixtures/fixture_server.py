#!/usr/bin/env python3
"""Deterministic local HTTP fixture for F3 capture sessions.

The server exposes a fixed JSON payload so that every agent receives exactly the
same input. It uses only the standard library, binds to the host side of the lab
veth by default (``10.203.1.1``) and writes one access line per request to
stderr.

Usage::

    python fixtures/fixture_server.py
    python fixtures/fixture_server.py --host 10.203.1.1 --port 8080

Endpoints:

- ``GET /health`` -> ``{"status": "ok"}``
- ``GET /data``   -> ``{"count": 6, "readings": [...]}``
- anything else   -> ``404`` with a JSON error
"""

from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

READINGS: list[dict[str, Any]] = [
    {"id": 1, "value": 10.0, "unit": "C"},
    {"id": 2, "value": 12.5, "unit": "C"},
    {"id": 3, "value": 11.0, "unit": "C"},
    {"id": 4, "value": 13.5, "unit": "C"},
    {"id": 5, "value": 9.5, "unit": "C"},
    {"id": 6, "value": 14.0, "unit": "C"},
]


def data_payload() -> dict[str, Any]:
    """Return the canonical ``/data`` response."""
    return {"count": len(READINGS), "readings": READINGS}


class FixtureHandler(BaseHTTPRequestHandler):
    """Serve the fixed AIGate fixture payload."""

    server_version = "AIGateFixture/1"
    sys_version = ""

    def do_GET(self) -> None:  # noqa: N802 - required by BaseHTTPRequestHandler
        if self.path == "/health":
            self._send_json(200, {"status": "ok"})
        elif self.path == "/data":
            self._send_json(200, data_payload())
        else:
            self._send_json(404, {"error": "not_found", "path": self.path})

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, sort_keys=True).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stderr.write(f"[fixture] {self.address_string()} - {fmt % args}\n")


def make_server(host: str, port: int) -> ThreadingHTTPServer:
    """Create the fixture server without starting it."""
    server = ThreadingHTTPServer((host, port), FixtureHandler)
    server.daemon_threads = True
    return server


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="AIGate local fixture server")
    parser.add_argument("--host", default="10.203.1.1", help="bind address")
    parser.add_argument("--port", type=int, default=8080, help="bind port")
    args = parser.parse_args(argv)

    server = make_server(args.host, args.port)
    host, port = server.server_address[:2]
    print(f"fixture listening on http://{host}:{port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("fixture stopped", file=sys.stderr, flush=True)
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

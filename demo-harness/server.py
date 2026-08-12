#!/usr/bin/env python3
"""
DEMO HARNESS — Solum-Demo repository only.

Mutates the Solum audit.jsonl file DIRECTLY on the filesystem (shared Docker
volume). This is intentionally outside the solum-sidecar HTTP API.

Solum itself has no tamper endpoint and must not gain one — that would be a
security anti-feature. Scenario 2 of this demo proves that an out-of-band
filesystem rewrite is detectable via GET /v1/audit/verify → chain_broken.

Do not port this handler into SynapticFour/Solum.
"""

from __future__ import annotations

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

AUDIT_PATH = Path(os.environ.get("AUDIT_PATH", "/data/audit.jsonl"))
BIND = os.environ.get("HARNESS_BIND", "0.0.0.0:8790")


def _json_response(handler: BaseHTTPRequestHandler, status: int, body: dict) -> None:
    payload = json.dumps(body, indent=2).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(payload)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(payload)


def simulate_tampering() -> dict:
    """
    Rewrite the first audit record's actor string in-place, matching the
    approach used in Solum's own FileAuditStore::detects_tampering unit test:
    alter event content without recomputing the hash chain.
    """
    if not AUDIT_PATH.is_file():
        return {
            "ok": False,
            "error": "audit_file_missing",
            "message": (
                f"No audit file at {AUDIT_PATH}. Run Scenario 1 first so the "
                "sidecar has written at least one audit record."
            ),
        }

    raw = AUDIT_PATH.read_text(encoding="utf-8")
    lines = [ln for ln in raw.splitlines() if ln.strip()]
    if not lines:
        return {
            "ok": False,
            "error": "audit_empty",
            "message": "audit.jsonl is empty — grant/encrypt something first.",
        }

    try:
        first = json.loads(lines[0])
    except json.JSONDecodeError as exc:
        return {
            "ok": False,
            "error": "corrupt_json",
            "message": f"Could not parse first audit line: {exc}",
        }

    event = first.get("event") or {}
    original_actor = event.get("actor", "")
    if not original_actor:
        return {
            "ok": False,
            "error": "no_actor",
            "message": "First record has no event.actor to mutate.",
        }

    tampered_actor = f"{original_actor}#DEMO-TAMPERED"
    if original_actor.endswith("#DEMO-TAMPERED"):
        return {
            "ok": True,
            "already_tampered": True,
            "message": "File already carries the demo tamper marker.",
            "actor": original_actor,
            "path": str(AUDIT_PATH),
            "warning": (
                "DEMO HARNESS — this mutation was applied outside solum-sidecar. "
                "The product API has no tamper route."
            ),
        }

    event["actor"] = tampered_actor
    first["event"] = event
    # Prefer in-place string replace (matches Solum FileAuditStore::detects_tampering)
    # so we only change the actor bytes and leave every other field's serialization alone.
    original_line = lines[0]
    needle = f'"actor":"{original_actor}"'
    replacement = f'"actor":"{tampered_actor}"'
    if needle in original_line:
        lines[0] = original_line.replace(needle, replacement, 1)
    else:
        # Fallback when JSON spacing differs from the compact form above.
        lines[0] = json.dumps(first, separators=(",", ":"), ensure_ascii=False)
    payload = "\n".join(lines) + "\n"
    # fsync so the sidecar's subsequent verify sees the mutation on the shared volume
    with AUDIT_PATH.open("w", encoding="utf-8") as fh:
        fh.write(payload)
        fh.flush()
        os.fsync(fh.fileno())

    return {
        "ok": True,
        "already_tampered": False,
        "path": str(AUDIT_PATH),
        "original_actor": original_actor,
        "tampered_actor": tampered_actor,
        "seq": first.get("seq"),
        "message": (
            "Rewrote event.actor on the first audit.jsonl record on disk. "
            "Hash fields were intentionally left unchanged so /v1/audit/verify "
            "should report chain_broken."
        ),
        "warning": (
            "DEMO HARNESS — filesystem rewrite only. Not available via the "
            "Solum sidecar API by design."
        ),
    }


class HarnessHandler(BaseHTTPRequestHandler):
    server_version = "SolumDemoHarness/1.0"

    def log_message(self, fmt: str, *args) -> None:
        print(f"[demo-harness] {self.address_string()} {fmt % args}")

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path in ("/demo/health", "/health", "/"):
            _json_response(
                self,
                200,
                {
                    "service": "solum-demo-harness",
                    "role": "DEMO_ONLY_NOT_SOLUM",
                    "audit_path": str(AUDIT_PATH),
                    "endpoints": {
                        "POST /demo/simulate-tampering": (
                            "Mutate audit.jsonl on the shared volume"
                        )
                    },
                },
            )
            return
        _json_response(self, 404, {"error": "not_found", "path": path})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        if path in ("/demo/simulate-tampering", "/simulate-tampering"):
            length = int(self.headers.get("Content-Length", "0") or "0")
            if length:
                _ = self.rfile.read(length)
            result = simulate_tampering()
            status = 200 if result.get("ok") else 400
            _json_response(self, status, result)
            return
        _json_response(self, 404, {"error": "not_found", "path": path})


def main() -> None:
    host, _, port_s = BIND.partition(":")
    port = int(port_s or "8790")
    print(
        "[demo-harness] DEMO ONLY — not part of Solum. "
        f"Listening on {host}:{port}, AUDIT_PATH={AUDIT_PATH}"
    )
    httpd = ThreadingHTTPServer((host, port), HarnessHandler)
    httpd.serve_forever()


if __name__ == "__main__":
    main()

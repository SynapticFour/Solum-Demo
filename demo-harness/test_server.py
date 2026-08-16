#!/usr/bin/env python3
"""Unit tests for demo-harness tamper helper (stdlib unittest)."""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

# Import sibling module.
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import server  # noqa: E402


def _write_record(path: Path, actor: str, pretty: bool = False) -> None:
    rec = {
        "seq": 1,
        "event": {"actor": actor, "event_type": "data.encrypt"},
        "hash": "deadbeef",
    }
    if pretty:
        line = json.dumps(rec)
    else:
        line = json.dumps(rec, separators=(",", ":"))
    path.write_text(line + "\n", encoding="utf-8")


class TamperTests(unittest.TestCase):
    def test_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            result = server.simulate_tampering(Path(tmp) / "nope.jsonl")
        self.assertFalse(result["ok"])
        self.assertEqual(result["error"], "audit_file_missing")

    def test_empty_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "audit.jsonl"
            p.write_text("\n\n", encoding="utf-8")
            result = server.simulate_tampering(p)
        self.assertFalse(result["ok"])
        self.assertEqual(result["error"], "audit_empty")

    def test_compact_mutate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "audit.jsonl"
            _write_record(p, "practitioner/amina")
            result = server.simulate_tampering(p)
            self.assertTrue(result["ok"])
            self.assertFalse(result["already_tampered"])
            self.assertEqual(result["tampered_actor"], "practitioner/amina#DEMO-TAMPERED")
            line = p.read_text(encoding="utf-8").splitlines()[0]
            rec = json.loads(line)
            self.assertEqual(rec["event"]["actor"], "practitioner/amina#DEMO-TAMPERED")
            self.assertEqual(rec["hash"], "deadbeef")
            again = server.simulate_tampering(p)
            self.assertTrue(again["already_tampered"])

    def test_pretty_fallback(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "audit.jsonl"
            rec = {"seq": 1, "event": {"actor": "intern/x"}, "hash": "abc"}
            p.write_text(json.dumps(rec) + "\n", encoding="utf-8")
            result = server.simulate_tampering(p)
            self.assertTrue(result["ok"])
            self.assertIn("intern/x#DEMO-TAMPERED", p.read_text(encoding="utf-8"))
            self.assertEqual(json.loads(p.read_text(encoding="utf-8").splitlines()[0])["hash"], "abc")


class TokenTests(unittest.TestCase):
    def test_expected_token_required(self) -> None:
        old = os.environ.pop("SOLUM_SIDECAR_TOKEN", None)
        try:
            with self.assertRaises(RuntimeError):
                server.expected_token()
        finally:
            if old is not None:
                os.environ["SOLUM_SIDECAR_TOKEN"] = old

    def test_expected_token_env(self) -> None:
        old = os.environ.get("SOLUM_SIDECAR_TOKEN")
        os.environ["SOLUM_SIDECAR_TOKEN"] = "unit-test-token"
        try:
            self.assertEqual(server.expected_token(), "unit-test-token")
        finally:
            if old is None:
                os.environ.pop("SOLUM_SIDECAR_TOKEN", None)
            else:
                os.environ["SOLUM_SIDECAR_TOKEN"] = old


if __name__ == "__main__":
    unittest.main()

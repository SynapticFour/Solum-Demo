# Demo harness (not Solum)

This directory is **demo-only scaffolding** for [SynapticFour/Solum-Demo](https://github.com/SynapticFour/Solum-Demo).

It exposes `POST /demo/simulate-tampering`, which rewrites `audit.jsonl` **on the shared Docker volume** so Scenario 2 can show a broken hash chain via Solum’s real `GET /v1/audit/verify`.

## Why this exists outside Solum

Solum’s sidecar deliberately has **no** tamper HTTP endpoint. Adding one would be a security anti-feature. Tampering in this demo happens only here, in harness code that must never be copied into [SynapticFour/Solum](https://github.com/SynapticFour/Solum).

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/demo/health` | Liveness + path info |
| POST | `/demo/simulate-tampering` | Mutate first record’s `event.actor` on disk |

Proxied by nginx as `/demo/*` on the dashboard origin (`http://localhost:8080`).

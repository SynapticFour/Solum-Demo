# Solum Demo

Interactive **local** demo of [Solum](https://github.com/SynapticFour/Solum)’s two Stage‑1 proofs that matter under regulatory pressure: **fail-closed authorization** and a **tamper-evident audit trail**.

This repository is **not** Solum. It consumes Solum only at the verified tag

`stage1-baseline-sidecar-custody-2026-08-01`

and never modifies the Solum product tree.

> **This is a local demo with ephemeral test keys — not a production environment.**

---

## Why this exists

Health-software vendors under **EHDS** (EU) and jurisdictions such as **Kenya’s DPA / SHA accreditation pressure** face the same compliance core: prove who could (and could not) touch clinical data, and prove the access log was not quietly rewritten afterward. Solum’s pilot framing starts from that shared denominator (see Solum’s `docs/PILOT-STRATEGY.md`): audit integrity, field encryption with accountable key custody, and FHIR-shaped interoperability.

This demo lets a visitor **feel** the first two on a laptop — without a cloud account and without shipping real patient data.

---

## Quick start

```bash
git clone https://github.com/SynapticFour/Solum-Demo.git
cd Solum-Demo
docker compose up --build
```

Then open **http://localhost:8080**

First build compiles `solum-sidecar` from the pinned Solum tag (Rust + libsodium inside Docker). Expect several minutes on a cold cache; later starts are much faster.

Stop with `Ctrl+C`, or `docker compose down`. Reset demo state (empty audit/consent files):

```bash
docker compose down -v
```

---

## What you will see

### Scenario 1 — Fail-closed authorization

1. Read the synthetic patient summary on the left.
2. Click **Encrypt as Dr. Amina** (capability `solum:crypto:encrypt`) — encryption succeeds (HTTP 200).
3. Click **Encrypt as Intern** (empty capability list) — Solum returns **HTTP 403**; no ciphertext side effect.
4. Watch the **Live audit log**: the intern’s refusal appears as an `authorization.denied` event without reloading the page.

## Screenshot hier

*(Platzhalter — echtes Screenshot nachträglich einfügen: Dr. Amina Erfolg + Intern 403 + `authorization.denied` im Live-Log.)*

### Scenario 2 — Tamper-evident audit trail

1. After Scenario 1 has written at least one audit record, click **Simulate tampering**.
2. That call hits the **demo harness** (`POST /demo/simulate-tampering`), which rewrites `audit.jsonl` **directly on the shared volume**. It does **not** go through the sidecar API — Solum has **no** tamper endpoint by design (adding one would be a security anti-feature).
3. Click **Verify audit chain** — the dashboard calls Solum’s real `GET /v1/audit/verify` and surfaces the `chain_broken` error (`audit chain broken at seq …`).

## Screenshot hier

*(Platzhalter — echtes Screenshot nachträglich einfügen: Harness-Tamper-Antwort + Verify mit `error: chain_broken`.)*

---

## Architecture (local only)

| Piece | Role |
|-------|------|
| `sidecar` | Multi-stage Docker image: clones Solum at the pinned tag, `cargo build --release -p solum-sidecar`, runs with `--ephemeral` |
| `dashboard` | nginx serves one buildless HTML/JS page and reverse-proxies `/v1/*` → sidecar |
| `demo-harness` | **Demo-only** Python service that mutates `audit.jsonl` on disk — **not part of Solum** |

Shared volume: `/data/audit.jsonl` + `/data/consent.jsonl`.

Default shared secret (local compose only): `solum-demo-local-token-not-for-production`, sent as header `X-Solum-Sidecar-Token`. Safe only because everything binds on your machine behind localhost:8080.

### Ephemeral keys — intentional demo simplification

Compose starts the sidecar with `--ephemeral`, `SOLUM_ALLOW_EPHEMERAL=1`, and Solum’s `dev-local.toml` profile from the same pinned tag.

**This demo uses ephemeral test keys.** They live only in process memory and vanish on restart — convenient and easy to reset, and **not** how you run a real evaluation or production system. Real deployments use **CustomerHeld** (`--keys-dir`) or **AWS-KMS** (library path today). Read Solum’s [`docs/customer/SECURITY-OVERVIEW.md`](https://github.com/SynapticFour/Solum/blob/stage1-baseline-sidecar-custody-2026-08-01/docs/customer/SECURITY-OVERVIEW.md) and [`SIDECAR-INTEGRATION.md`](https://github.com/SynapticFour/Solum/blob/stage1-baseline-sidecar-custody-2026-08-01/docs/customer/SIDECAR-INTEGRATION.md).

### Demo harness vs product boundary

```
demo-harness/     ← Solum-Demo only (filesystem rewrite)
solum-sidecar     ← product binary from SynapticFour/Solum @ pinned tag
```

Never copy `demo-harness/` into the Solum repository.

---

## Repository layout

```
Solum-Demo/
├── README.md
├── Dockerfile                 # builds sidecar from pinned Solum tag
├── docker-compose.yml
├── dashboard/
│   └── index.html             # single-page demo UI (no npm)
├── demo-harness/              # DEMO ONLY — not Solum
│   ├── Dockerfile
│   ├── README.md
│   └── server.py
└── nginx/
    └── default.conf           # / → UI, /v1 → sidecar, /demo → harness
```

---

## Requirements

- Docker with Compose v2
- Network on first build (clones public `SynapticFour/Solum` + fetches `ferrum-core`)

---

## License / contact

Demo scaffolding in this repo is provided for evaluation walkthroughs by Synaptic Four.
Solum itself remains under its own license in [SynapticFour/Solum](https://github.com/SynapticFour/Solum).

Contact: [contact@synapticfour.com](mailto:contact@synapticfour.com) · [synapticfour.com](https://synapticfour.com)

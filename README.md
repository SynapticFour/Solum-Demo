# Solum Demo

Interactive **local** demo of [Solum](https://github.com/SynapticFour/Solum) Stage‑1 proofs (**fail-closed authorization**, **tamper-evident audit**) plus **automated smokes** for consent and optional H3 Track B / jurisdiction profiles.

Coverage map (what this repo vs Showcase/Solum owns): [`docs/COVERAGE.md`](docs/COVERAGE.md).

> **Local demo with ephemeral test keys — not a production environment.**

---

## Quick start

```bash
git clone https://github.com/SynapticFour/Solum-Demo.git
cd Solum-Demo
make up          # or: docker compose up --build -d
# open http://localhost:8080
make smoke-stage1
make smoke-consent
```

If `:8080` is taken (e.g. Ferrum gateway), use another host port:

```bash
SOLUM_DEMO_PORT=8088 make up
SOLUM_DEMO_PORT=8088 make smoke-stage1 smoke-consent
```

Cold build compiles `solum-sidecar` from the pinned Solum tag (Rust + libsodium). Expect several minutes once.

```bash
make down        # stop
make reset       # wipe volumes
```

---

## Verifiable smokes (`make`)

| Target | Proves | Needs |
|--------|--------|-------|
| `smoke-stage1` | Encrypt allow/deny + audit chain break | `make up` |
| `smoke-consent` | Consent grant → status → revoke | `make up` |
| `smoke-h3` | CDR template/EHR/composition, FHIR Patient, subject-link, dual-write, AQL | `make up-h3` (soft-skip if down) |
| `smoke-profile` | `kenya-dpa` / `eu-ehds` residency refuse | sibling `../Solum` (soft-skip) |
| `smoke-all` | All of the above | — |

Ecosystem integrations **not** in this repo (Showcase):

- Ferrum consent teeth: `make h21-teeth` in SynapticFour-Showcase  
- Path E+ live soft smoke: `make path-eplus-smoke`  
- Evidence Pack / golden path with Solum: `make golden-path-with-solum`

---

## Interactive UI (Stage-1)

### Scenario 1 — Fail-closed authorization

Encrypt as Dr. Amina (`solum:crypto:encrypt` → 200) vs Intern (empty caps → 403 + `authorization.denied`).

### Scenario 2 — Tamper-evident audit trail

Harness mutates `audit.jsonl` on disk → `GET /v1/audit/verify` → `chain_broken`.

### Scenario 3 — Consent grant / status / revoke

UI buttons mirror `make smoke-consent` (`POST /v1/consent/grant` → status → revoke).

---

## Architecture

| Piece | Role |
|-------|------|
| `sidecar` | Pinned Solum tag, `--ephemeral`, `dev-local.toml` |
| `dashboard` | nginx :8080 → UI + `/v1` + `/demo` |
| `demo-harness` | Demo-only audit tamper (**not** Solum) |

Default token: `solum-demo-local-token-not-for-production` (`X-Solum-Sidecar-Token`).

### H3 EHRbase overlay (Track B)

```bash
make up-h3       # EHRbase :8081 + sidecar-h3 :8787 from ../Solum
make smoke-h3
make down-h3
```

Honesty: hub-class JVM EHRbase; not Pi; not a production EHR. See Solum [`docs/H3-EHRBASE-SPIKE.md`](https://github.com/SynapticFour/Solum/blob/main/docs/H3-EHRBASE-SPIKE.md).

**Two build sources (do not confuse):**

| Stack | Pin / source | File |
|-------|----------------|------|
| Stage-1 dashboard + `smoke-stage1` / `smoke-consent` | Solum git tag `stage1-baseline-sidecar-custody-2026-08-01` | `Dockerfile` · [`PINNED_VERSIONS.txt`](PINNED_VERSIONS.txt) |
| H3 Track B + `smoke-h3` | Local sibling `../Solum` (current tree) | `docker-compose.ehrbase-sidecar.yml` |

After pulling Solum, rebuild H3 with `make down-h3 && make up-h3`.

---

## Repository layout

```
Solum-Demo/
├── Makefile
├── PINNED_VERSIONS.txt
├── docs/COVERAGE.md
├── scripts/smoke-*.sh
├── .github/workflows/   # smoke-syntax + smoke-stage1 (live Docker)
├── docker-compose.yml
├── docker-compose.ehrbase.yml
├── docker-compose.ehrbase-sidecar.yml
├── Dockerfile                 # Stage-1 pin
├── dashboard/  demo-harness/  nginx/
```

---

## License / contact

Demo scaffolding for evaluation walkthroughs by Synaptic Four.  
Solum: [SynapticFour/Solum](https://github.com/SynapticFour/Solum) · [synapticfour.com](https://synapticfour.com)

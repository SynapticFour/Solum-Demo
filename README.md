# Solum Demo

Interactive **local** demo of [Solum](https://github.com/SynapticFour/Solum) Stage‑1 proofs (**fail-closed authorization**, **consent-gated crypto / Deny B**, **tamper-evident audit**, **HELIOS-oriented export envelope**) plus automated smokes for Track B H3 and sibling Solum claims (FHIR IPS, Kenya, migration rehearsal).

Coverage map (what this repo vs Showcase/Solum owns): [`docs/COVERAGE.md`](docs/COVERAGE.md).  
Product claim → proof matrix: Solum [`docs/CLAIMS-PROOF-TRAIL.md`](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md).

> **Local demo with ephemeral test keys — not a production environment.**  
> Audit export is a **HELIOS-oriented envelope** only — Solum does **not** perform live HELIOS signing here.

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

While developing Solum beside this repo, prefer the sibling build (always matches `../Solum` HEAD):

```bash
make up-sibling
make smoke-stage1 smoke-consent
```

If `:8080` is taken (e.g. Ferrum gateway), use another host port:

```bash
SOLUM_DEMO_PORT=8088 make up
SOLUM_DEMO_PORT=8088 make smoke-stage1 smoke-consent
```

Cold build compiles `solum-sidecar` from the pinned Solum commit (Rust + libsodium). Expect several minutes once.

```bash
make down        # stop
make reset       # wipe volumes
```

---

## Verifiable smokes (`make`)

| Target | Proves | Needs |
|--------|--------|-------|
| `smoke-stage1` | Consent-gated encrypt allow; empty-caps deny + `authorization.denied`; HELIOS export format; audit chain break | `make up` |
| `smoke-consent` | Grant → encrypt → decrypt → revoke → decrypt refuse + `consent.denied` (Deny B) | `make up` |
| `smoke-h3` | CDR template/EHR/composition, FHIR Patient, subject-link, dual-write, AQL | `make up-h3` (soft-skip if down) |
| `smoke-profile` | `kenya-dpa` / `eu-ehds` residency; KE ephemeral refuse; transfer fail-closed; planned NG/SA only | sibling `../Solum` (soft-skip) |
| `smoke-fhir-ips` | `solum fhir export-ips` + structural validate | sibling `../Solum` (soft-skip) |
| `smoke-migration` | Prefer/Cut-over **tooling** dry rehearsal | sibling `../Solum` (soft-skip) |
| `smoke-claims-proof` | Solum `./scripts/demo-claims-proof.sh` one-shot | sibling `../Solum` (soft-skip) |
| `smoke-all` | stage1 + consent + soft sibling smokes | — |

Ecosystem integrations **not** in this repo (Showcase):

- Ferrum consent teeth: `make h21-teeth` in SynapticFour-Showcase  
- Path E+ live soft smoke: `make path-eplus-smoke`  
- Evidence Pack / golden path with Solum: `make golden-path-with-solum`

---

## Interactive UI (Stage-1)

### Scenario 1 — Fail-closed authorization (+ consent gate)

Encrypt requires an active consent grant for `(subject, purpose)` covering `patient_summary`. Dr. Amina (`solum:crypto:encrypt`) succeeds after auto-grant; Intern (empty caps) → 403 + `authorization.denied`.

### Scenario 2 — Tamper-evident audit trail

Harness mutates `audit.jsonl` on disk → `GET /v1/audit/verify` → `chain_broken`.

### Scenario 3 — Consent grant / status / revoke

UI buttons for grant / status / revoke (`POST /v1/consent/*`).

### Scenario 4 — Deny B (decrypt after revoke)

Encrypt while granted → revoke → decrypt must fail; watch `consent.denied` in the live audit log.

---

## Architecture

| Piece | Role |
|-------|------|
| `sidecar` | Pinned Solum **commit** (or sibling tree), `--ephemeral`, `dev-local.toml` |
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

**Two Stage-1 build sources (do not confuse):**

| Stack | Pin / source | File |
|-------|----------------|------|
| Stage-1 `make up` | Solum git **commit** `Solum-ref` in [`PINNED_VERSIONS.txt`](PINNED_VERSIONS.txt) | `Dockerfile` |
| Stage-1 `make up-sibling` | Local sibling `../Solum` | `Dockerfile.sibling` · `docker-compose.sibling.yml` |
| H3 Track B + `smoke-h3` | Local sibling `../Solum` | `docker-compose.ehrbase-sidecar.yml` |

After pulling Solum, rebuild with `make down && make up` (or `make up-sibling`) and `make down-h3 && make up-h3`.

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
├── docker-compose.sibling.yml
├── docker-compose.ehrbase.yml
├── docker-compose.ehrbase-sidecar.yml
├── Dockerfile / Dockerfile.sibling
├── dashboard/  demo-harness/  nginx/
```

---

## License / contact

Demo scaffolding for evaluation walkthroughs by Synaptic Four.  
Solum: [SynapticFour/Solum](https://github.com/SynapticFour/Solum) · [synapticfour.com](https://synapticfour.com)

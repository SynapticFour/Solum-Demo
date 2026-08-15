# Solum Demo

Interactive **local developer** walkthrough of [Solum](https://github.com/SynapticFour/Solum) Stage‑1 proofs (**empty-`capability[]` deny**, **consent-gated crypto / Deny B**, **tamper-evident audit**, **HELIOS-oriented export envelope**) plus automated smokes for Track B H3 and sibling Solum claims (FHIR IPS, Kenya, migration rehearsal).

**This is not a customer evaluation** and not a production environment. It uses Solum `dev-local.toml` (ephemeral keys; client-asserted `capability[]`). Solum’s own profile forbids that posture for customer evaluations. Pilot org-IAM lives in Solum tests / Showcase, not here.

Coverage map: [`docs/COVERAGE.md`](docs/COVERAGE.md).  
Product claim → proof matrix: Solum [`docs/CLAIMS-PROOF-TRAIL.md`](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md).  
Scope decision: [`docs/adr/0001-demo-scope.md`](docs/adr/0001-demo-scope.md).

> Audit export is a **HELIOS-oriented envelope** only — Solum does **not** perform live HELIOS signing here.

---

## Quick start

```bash
git clone https://github.com/SynapticFour/Solum-Demo.git
cd Solum-Demo
make up          # reads Solum-ref from PINNED_VERSIONS.txt
# open http://127.0.0.1:8080  (loopback only)
make smoke-ci    # smoke-stage1 + smoke-consent
```

While developing Solum beside this repo, prefer the sibling build (current `../Solum` tree, **not** the pin):

```bash
make up-sibling
make smoke-ci
```

If `:8080` is taken (e.g. Ferrum gateway), use another **loopback** host port:

```bash
SOLUM_DEMO_PORT=8088 make up
SOLUM_DEMO_PORT=8088 make smoke-ci
```

Cold build compiles `solum-sidecar` from the pinned Solum commit (Rust + libsodium). Expect several minutes once.

```bash
make down        # stop
make reset       # wipe volumes
make check       # pin drift, LICENSE, bash -n, harness unit tests
```

---

## Verifiable smokes (`make`)

| Target | Proves | Needs |
|--------|--------|-------|
| `smoke-stage1` | Consent-gated encrypt allow; empty `capability[]` → 403 + `access.denied`; HELIOS export `format`; audit `error=chain_broken` | `make up` |
| `smoke-consent` | Grant → encrypt → decrypt → revoke → decrypt 400/403 with `consent denied` | `make up` |
| `smoke-h3` | CDR template/EHR/composition, FHIR Patient, subject-link, dual-write **façade** + `link_cdr=true` dead-letter, AQL | `make up-h3` (`SOLUM_DEMO_H3_REQUIRE=1` fails if down) |
| `smoke-profile` | `kenya-dpa` / `eu-ehds` residency; KE ephemeral refuse; transfer fail-closed; planned NG/SA only | sibling `../Solum` |
| `smoke-fhir-ips` | `solum fhir export-ips` + structural checks **on that file** | sibling `../Solum` |
| `smoke-migration` | Prefer/Cut-over **tooling** dry rehearsal | sibling `../Solum` |
| `smoke-claims-proof` | Solum `./scripts/demo-claims-proof.sh` one-shot | sibling `../Solum` |
| `smoke-ci` | stage1 + consent | stack up |
| `smoke-all` | all of the above; sibling/H3 **skip = fail** | pin stack + sibling + H3 |

Ecosystem integrations **not** in this repo (Showcase):

- Ferrum consent teeth: `make h21-teeth` in SynapticFour-Showcase  
- Path E+ live soft smoke: `make path-eplus-smoke`  
- Evidence Pack / golden path with Solum: `make golden-path-with-solum`

---

## Interactive UI (Stage-1)

### Scenario 1 — Fail-closed empty `capability[]`

Encrypt requires an active consent grant for `(subject, purpose)` covering `patient_summary`. The JSON body must include `solum:crypto:encrypt` (**client-asserted** on `dev-local`). Empty `capability[]` → 403 + `access.denied`. There is no intern role.

### Scenario 2 — Tamper-evident audit trail

Harness mutates `audit.jsonl` on disk (token required; nginx injects it) → `GET /v1/audit/verify` → `error=chain_broken`.

### Scenario 3 — Consent grant / status / revoke

UI buttons for grant / status / revoke (`POST /v1/consent/*`).

### Scenario 4 — Deny B (decrypt after revoke)

Encrypt while granted → revoke → decrypt must fail; watch `consent.denied` in the live audit log.

---

## Architecture

| Piece | Role |
|-------|------|
| `sidecar` | Pinned Solum **commit** (or sibling tree), `--ephemeral`, `dev-local.toml` |
| `dashboard` | nginx `127.0.0.1:8080` → UI + `/v1` + `/demo`; injects sidecar token |
| `demo-harness` | Demo-only audit tamper (**not** Solum), uid 10001, token on POST |

Default token (compose/env only, not in the HTML): `solum-demo-local-token-not-for-production` (`X-Solum-Sidecar-Token`).

### Three binaries (do not confuse)

| Stack | Pin / source | File |
|-------|----------------|------|
| Stage-1 `make up` | Solum git **commit** `Solum-ref` in [`PINNED_VERSIONS.txt`](PINNED_VERSIONS.txt) | `Dockerfile` |
| Stage-1 `make up-sibling` | Local sibling `../Solum` (image build drops host `.cargo/config.toml`) | `Dockerfile.sibling` · `docker-compose.sibling.yml` |
| H3 Track B + `smoke-h3` | Local sibling `../Solum` | `docker-compose.ehrbase-sidecar.yml` |

After pulling Solum, rebuild with `make down && make up` (or `make up-sibling`) and `make down-h3 && make up-h3`.

### H3 EHRbase overlay (Track B)

```bash
make up-h3       # EHRbase 127.0.0.1:8081 + sidecar-h3 127.0.0.1:8787 from ../Solum
make smoke-h3
make down-h3
```

Honesty: hub-class JVM EHRbase; not Pi; not a production EHR. Dual-write with `link_cdr=true` is **refused** (example compositions are not patient data). See Solum [`docs/H3-EHRBASE-SPIKE.md`](https://github.com/SynapticFour/Solum/blob/main/docs/H3-EHRBASE-SPIKE.md).

---

## Repository layout

```
Solum-Demo/
├── LICENSE / NOTICE
├── Makefile
├── PINNED_VERSIONS.txt
├── docs/COVERAGE.md
├── docs/adr/
├── scripts/smoke-*.sh
├── .github/workflows/   # smoke-syntax (make check) + smoke-stage1 (PR + main)
├── docker-compose.yml
├── docker-compose.sibling.yml
├── docker-compose.ehrbase.yml
├── docker-compose.ehrbase-sidecar.yml
├── Dockerfile / Dockerfile.sibling
├── dashboard/  demo-harness/  nginx/
```

---

## License / contact

Demo scaffolding (this repository’s Compose, UI, harness, smokes, docs) is **Apache License 2.0**. See [LICENSE](LICENSE).

The sidecar **image contains Solum**, which is **Business Source License 1.1** — not Apache-2.0. See [NOTICE](NOTICE) and [SynapticFour/Solum LICENSE](https://github.com/SynapticFour/Solum/blob/main/LICENSE).

Contact: [synapticfour.com](https://synapticfour.com)

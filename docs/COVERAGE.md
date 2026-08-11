# Solum-Demo coverage map

**Date:** 2026-08-11  
**Honesty:** This repo is an **interactive + smoke** mirror of Solum — not the full product test suite. Unit/integration depth lives in **Solum** (`cargo test` / `./scripts/verify.sh`) and **Showcase** (teeth, Path E+, evidence pack).

**Pins:** [`PINNED_VERSIONS.txt`](../PINNED_VERSIONS.txt) — Stage-1 builds **Solum-ref** (commit with consent-gated crypto); H3 builds local `../Solum`. Dev alignment: `make up-sibling`.

**Master claim map (product):** [Solum CLAIMS-PROOF-TRAIL.md](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md)

## What Solum-Demo verifies (tangible)

| Layer | Claim ids | How | Command |
|-------|-----------|-----|---------|
| HELIOS-oriented audit export envelope | A6 | Export `format` contains `solum-audit-helios*` — **not** live signing | `make smoke-stage1` |
| Fail-closed crypto authz | A2 | Empty caps → 403 + `authorization.denied` | `make smoke-stage1` / UI Scenario 1 |
| Tamper-evident audit | — | Harness rewrite → chain break | `make smoke-stage1` / UI Scenario 2 |
| Consent + Deny B | A3 | Grant → encrypt → decrypt → revoke → decrypt refuse + `consent.denied` | `make smoke-consent` / UI Scenario 3–4 |
| H3 CDR / FHIR / AQL / dual-write / subject-link | A12 | EHRbase overlay → `artifacts/smoke-h3/` | `make smoke-h3` (soft-skip if down) |
| EU / Kenya residency + KE ephemeral refuse + transfer fail-closed + planned NG/SA | A7 A8 A13 | Sibling Solum `check` + unit | `make smoke-profile` (soft-skip) |
| IPS Bundle structural (+ optional HL7 JAR) | A9 A10 | `solum fhir export-ips` + validate | `make smoke-fhir-ips` (soft-skip) |
| Migration Prefer/Cut-over **tooling** dry run | A15 | Solum rehearsal script | `make smoke-migration` (soft-skip) |
| Full Track A claims one-shot | A1–A8+ | Solum `demo-claims-proof.sh` | `make smoke-claims-proof` (soft-skip) |

## Forbidden claims (do not say in demos)

- EHDS / MDR / TI / gematik / ISiK certified
- Live HELIOS signing / turnkey attestation bridge
- Production Kenya / Nigeria / SA SoR from this dashboard
- That ephemeral Stage-1 keys are CustomerHeld production custody

## Proof path (portfolio)

| Proof | Where |
|-------|--------|
| Claims matrix | Solum [CLAIMS-PROOF-TRAIL.md](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md) |
| Track A CLI worked example | Solum [WORKED-EXAMPLE.md](https://github.com/SynapticFour/Solum/blob/main/docs/WORKED-EXAMPLE.md) · `../Solum/examples/compliance-worked-example/run.sh` |
| Track B evidence packaging | Solum [H3-WORKED-EVIDENCE.md](https://github.com/SynapticFour/Solum/blob/main/docs/H3-WORKED-EVIDENCE.md) · **this** Demo `make smoke-h3` |
| FHIR / DE gap | Solum [FHIR-VALIDATION.md](https://github.com/SynapticFour/Solum/blob/main/docs/FHIR-VALIDATION.md) · [DE-FHIR-GAP.md](https://github.com/SynapticFour/Solum/blob/main/docs/DE-FHIR-GAP.md) |

**Proof path Phase 2:** `make smoke-h3` is the Track B evidence command; outputs under `artifacts/smoke-h3/` (gitignored). Set `SOLUM_DEMO_H3_REQUIRE=1` to fail when the stack is down.

## What lives elsewhere (still required for full ecosystem proof)

| Capability | Where |
|------------|--------|
| Solum unit/HTTP tests + `verify.sh` | Solum |
| Ferrum consent teeth (DRS/WES 403) | Showcase `make h21-teeth` |
| Org-IAM CAP mapping | Showcase `make h22-org-cap` + Solum tests |
| Path E+ soft live | Showcase `make path-eplus-smoke` |
| Evidence Pack / golden path | Showcase `make evidence-pack` / `golden-path-with-solum` |
| Kenya counsel / PRODUCTION | Human — Showcase [HORIZON-OPEN-GATES](https://github.com/SynapticFour/SynapticFour-Showcase/blob/main/docs/pilots/HORIZON-OPEN-GATES.md) |
| Typed `encrypt_patient_summary_as` unit | Solum (A14) — not HTTP demo |

## Compose profiles

| File | Role | Custody |
|------|------|---------|
| `docker-compose.yml` | Stage-1 dashboard (`SOLUM_DEMO_PORT`, default :8080) from **Solum-ref** | Ephemeral + `dev-local` (demo only) |
| `docker-compose.sibling.yml` | Same UI, sidecar from **../Solum** | Ephemeral + `dev-local` |
| `docker-compose.ehrbase.yml` | EHRbase :8081 | N/A |
| `docker-compose.ehrbase-sidecar.yml` | Track B sidecar :8787 from **../Solum** | Ephemeral + `dev-local` |

Pilot profiles (`eu-ehds`, `kenya-dpa`) **refuse ephemeral** — exercised via `smoke-profile`, not the interactive dashboard.

## CI expectation

| Workflow | When | What |
|----------|------|------|
| `smoke-syntax` | every PR / push | `bash -n` all smokes + Makefile / COVERAGE present |
| `smoke-stage1` | `main` push, weekly, `workflow_dispatch` | `docker compose up --build` + `smoke-stage1` + `smoke-consent` |

H3 / profile / FHIR / migration live proofs stay local (`make smoke-all`) — sibling Solum + EHRbase are too heavy for default CI.

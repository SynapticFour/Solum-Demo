# Solum-Demo coverage map

**Date:** 2026-08-15  
**Honesty:** This repo is an **interactive + smoke** mirror of Solum — not the full product test suite. Unit/integration depth lives in **Solum** (`cargo test` / `./scripts/verify.sh`) and **Showcase** (teeth, Path E+, evidence pack).

**Not a customer evaluation.** Stage-1 uses Solum `dev-local.toml` (ephemeral keys, client-asserted `capability[]`). Solum’s own profile text forbids that posture for customer evaluations. Pilot org-IAM is out of scope here.

**Pins:** [`PINNED_VERSIONS.txt`](../PINNED_VERSIONS.txt) is the source of truth (`make up` exports `Solum-ref`). That SHA must equal Solum [`docs/BASELINE.md`](https://github.com/SynapticFour/Solum/blob/main/docs/BASELINE.md) **Verified commit**. H3 builds local `../Solum`, which is a **different binary** from Stage-1. Image policy: [`IMAGE-PIN-POLICY.md`](IMAGE-PIN-POLICY.md).

**Master claim map (product):** [Solum CLAIMS-PROOF-TRAIL.md](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md)

## What Solum-Demo verifies (tangible)

| Layer | Claim ids | How | Command |
|-------|-----------|-----|---------|
| HELIOS-oriented audit export envelope | A6 | Export JSON `format` starts with `solum-audit-helios` — **not** live signing | `make smoke-stage1` |
| Fail-closed empty `capability[]` | A2 | Empty caps → 403 + `authorization.denied`. **Not** physician/intern RBAC | `make smoke-stage1` / UI Scenario 1 |
| Tamper-evident audit | — | Harness rewrite → verify `error=chain_broken` | `make smoke-stage1` / UI Scenario 2 |
| Consent + Deny B | A3 | Grant → encrypt → decrypt → revoke → decrypt 400/403 with `consent denied` + `consent.denied` | `make smoke-consent` / UI Scenario 3–4 |
| H3 CDR / FHIR / AQL / subject-link | A12 | EHRbase overlay → `artifacts/smoke-h3/` | `make smoke-h3` (`SOLUM_DEMO_H3_REQUIRE=1` to fail if down) |
| Dual-write façade + refuse example CDR | A12 (partial) | `link_cdr=false` → 201 `dead_lettered=false`; `link_cdr=true` → 202 `dead_lettered=true` (Solum will not commit example compositions as patient data) | `make smoke-h3` |
| EU / Kenya residency + KE ephemeral refuse + transfer fail-closed + planned NG/SA | A7 A8 A13 | Sibling Solum `check` + unit | `make smoke-profile` |
| IPS Bundle structural of **CLI** output | A9 | `solum fhir export-ips` then structural checks on **that** file (no re-export) | `make smoke-fhir-ips` |
| Migration Prefer/Cut-over **tooling** dry run | A15 | Solum rehearsal script | `make smoke-migration` |
| Full Track A claims one-shot | A1–A8+ | Solum `demo-claims-proof.sh` | `make smoke-claims-proof` |

`make smoke-all` sets `*_REQUIRE=1` for every sibling/H3 smoke: a skip is a **failure**. Individual smokes still skip when the stack is absent so a laptop without EHRbase can run Stage-1 only.

## Forbidden claims (do not say in demos)

- EHDS / MDR / TI / gematik / ISiK certified
- Live HELIOS signing / turnkey attestation bridge
- Production Kenya / Nigeria / SA SoR from this dashboard
- That ephemeral Stage-1 keys are CustomerHeld production custody
- That empty-`capability[]` deny is hospital RBAC or org-IAM
- That dual-write in this demo writes a live EHR composition (`link_cdr=true` is refused)
- That this stack is a customer evaluation of Solum

## Proof path (portfolio)

| Proof | Where |
|-------|--------|
| Claims matrix | Solum [CLAIMS-PROOF-TRAIL.md](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md) |
| Track A CLI worked example | Solum [WORKED-EXAMPLE.md](https://github.com/SynapticFour/Solum/blob/main/docs/WORKED-EXAMPLE.md) · `../Solum/examples/compliance-worked-example/run.sh` |
| Track B evidence packaging | Solum [H3-WORKED-EVIDENCE.md](https://github.com/SynapticFour/Solum/blob/main/docs/H3-WORKED-EVIDENCE.md) · **this** Demo `make smoke-h3` |
| FHIR / DE gap | Solum [FHIR-VALIDATION.md](https://github.com/SynapticFour/Solum/blob/main/docs/FHIR-VALIDATION.md) · [DE-FHIR-GAP.md](https://github.com/SynapticFour/Solum/blob/main/docs/DE-FHIR-GAP.md) |

**Proof path Phase 2:** `make smoke-h3` is the Track B evidence command; outputs under `artifacts/smoke-h3/` (gitignored).

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

| File | Role | Custody | Binary |
|------|------|---------|--------|
| `docker-compose.yml` | Stage-1 dashboard (`127.0.0.1:${SOLUM_DEMO_PORT:-8080}`) from **Solum-ref** | Ephemeral + `dev-local` (demo only) | Pin |
| `docker-compose.sibling.yml` | Same UI, sidecar from **../Solum** (strips host `.cargo/config.toml`) | Ephemeral + `dev-local` | Sibling HEAD |
| `docker-compose.ehrbase.yml` | EHRbase `127.0.0.1:8081` | N/A | Image pin |
| `docker-compose.ehrbase-sidecar.yml` | Track B sidecar `127.0.0.1:8787` from **../Solum** | Ephemeral + `dev-local` | Sibling HEAD |

Pilot profiles (`eu-ehds`, `kenya-dpa`) **refuse ephemeral** — exercised via `smoke-profile`, not the interactive dashboard.

## CI expectation

| Workflow | When | What |
|----------|------|------|
| `smoke-syntax` | every PR / push | `make check` (pin drift, LICENSE, `bash -n`, harness unittest) |
| `smoke-stage1` | every PR / `main` push / `workflow_dispatch` | `docker compose up --build` + `smoke-stage1` + `smoke-consent` |

H3 / profile / FHIR / migration / claims live proofs stay local (`make smoke-all`) — sibling Solum + EHRbase are too heavy for default CI. There is **no weekly schedule**.

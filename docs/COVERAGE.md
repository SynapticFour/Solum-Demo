# Solum-Demo coverage map

**Date:** 2026-08-10  
**Honesty:** This repo is an **interactive + smoke** mirror of Solum — not the full product test suite. Unit/integration depth lives in **Solum** (`cargo test`) and **Showcase** (teeth, Path E+, evidence pack).

**Pins:** [`PINNED_VERSIONS.txt`](../PINNED_VERSIONS.txt) — Stage-1 builds `Solum-tag`; H3 builds local `../Solum` (not the Stage-1 tag).

## What Solum-Demo verifies (tangible)

| Layer | How | Command |
|-------|-----|---------|
| Fail-closed crypto authz | UI Scenario 1 + curl | `make smoke-stage1` |
| Tamper-evident audit | UI Scenario 2 + harness | `make smoke-stage1` |
| Consent grant/status/revoke | UI Scenario 3 + HTTP smoke | `make smoke-consent` |
| H3 CDR / FHIR / AQL / dual-write / subject-link | EHRbase overlay + curl → `artifacts/smoke-h3/` | `make smoke-h3` (soft-skip if down) |
| `kenya-dpa` / `eu-ehds` refuse wrong region | Sibling Solum `solum check` | `make smoke-profile` (soft-skip if no ../Solum) |

## Proof path (portfolio)

Solum’s documented proof stack (Track A worked example, Track B evidence packaging, FHIR/DE gap docs) lives in the product repo:

- [WORKED-EXAMPLE.md](https://github.com/SynapticFour/Solum/blob/main/docs/WORKED-EXAMPLE.md) — CLI consent/crypto/audit (`../Solum/examples/compliance-worked-example/run.sh`)
- [H3-WORKED-EVIDENCE.md](https://github.com/SynapticFour/Solum/blob/main/docs/H3-WORKED-EVIDENCE.md) — this Demo’s `make smoke-h3` + retained `artifacts/smoke-h3/`
- [FHIR-VALIDATION.md](https://github.com/SynapticFour/Solum/blob/main/docs/FHIR-VALIDATION.md) · [DE-FHIR-GAP.md](https://github.com/SynapticFour/Solum/blob/main/docs/DE-FHIR-GAP.md)

**Proof path Phase 2:** `make smoke-h3` is the Track B evidence command; outputs under `artifacts/smoke-h3/` (gitignored). Set `SOLUM_DEMO_H3_REQUIRE=1` to fail when the stack is down.


## What lives elsewhere (still required for full ecosystem proof)

| Capability | Where |
|------------|--------|
| Solum unit/HTTP tests | Solum `cargo test -p solum-sidecar` etc. |
| Ferrum consent teeth (DRS/WES 403) | Showcase `make h21-teeth` |
| Org-IAM CAP mapping | Showcase `make h22-org-cap` + Solum tests |
| Path E+ soft live | Showcase `make path-eplus-smoke` |
| Evidence Pack / golden path | Showcase `make evidence-pack` / `golden-path-with-solum` |
| Kenya counsel / PRODUCTION | Human — Showcase [HORIZON-OPEN-GATES](https://github.com/SynapticFour/SynapticFour-Showcase/blob/main/docs/pilots/HORIZON-OPEN-GATES.md) |

## Compose profiles

| File | Role | Custody |
|------|------|---------|
| `docker-compose.yml` | Stage-1 dashboard (`SOLUM_DEMO_PORT`, default :8080) | Ephemeral + `dev-local` (demo only) |
| `docker-compose.ehrbase.yml` | EHRbase :8081 (health: `/ehrbase/rest/status`) | N/A |
| `docker-compose.ehrbase-sidecar.yml` | Track B sidecar :8787 from **../Solum** | Ephemeral + `dev-local` |

Pilot profiles (`eu-ehds`, `kenya-dpa`) **refuse ephemeral** — they are exercised via `smoke-profile`, not the interactive dashboard.

## CI expectation

| Workflow | When | What |
|----------|------|------|
| `smoke-syntax` | every PR / push | `bash -n` smokes + Makefile / COVERAGE present |
| `smoke-stage1` | `main` push, weekly, `workflow_dispatch` | `docker compose up --build` + `smoke-stage1` + `smoke-consent` |

H3 / profile live proofs stay local (`make up-h3` · `make smoke-h3` · `make smoke-profile`) — sibling Solum + EHRbase are too heavy for default CI.

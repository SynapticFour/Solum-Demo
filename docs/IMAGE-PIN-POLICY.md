# Image pin policy

**Status:** 2026-08-12 · org level-up **C10**  
**Repo:** Solum-Demo  

## Policy

| Context | Rule |
|---------|------|
| **Stage-1 / H3 smokes** | Pin third-party images to the versions in compose (today: `nginx:1.27-alpine`, `ehrbase/ehrbase:2.34.0`, `ehrbase/ehrbase-v2-postgres:16.2`). Bumps require a PR + smoke re-run. |
| **Solum binary / sidecar** | Prefer sibling build from pinned Solum tag/SHA (see Demo COVERAGE / Showcase pins), not an unnamed floating image. |
| **Floating tags** | Do not introduce `:latest` for EHRbase, Postgres, or nginx in paths that claim Stage-1 proofs. |

## Current pins (compose)

| Image | Pin |
|-------|-----|
| nginx | `1.27-alpine` |
| EHRbase Postgres | `ehrbase/ehrbase-v2-postgres:16.2` |
| EHRbase | `ehrbase/ehrbase:2.34.0` |

## Review

Monthly: [MONTHLY-DEPENDENCY-HYGIENE](https://github.com/SynapticFour/synapticfour-infra/blob/main/docs/MONTHLY-DEPENDENCY-HYGIENE.md).

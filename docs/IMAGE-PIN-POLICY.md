# Image pin policy

**Status:** 2026-08-15  
**Repo:** Solum-Demo  

## Policy

| Context | Rule |
|---------|------|
| **Stage-1 / H3 smokes** | Pin third-party images to the versions (and nginx digest) in compose / `PINNED_VERSIONS.txt`. Bumps require a PR + smoke re-run. |
| **Solum binary / sidecar** | `make up` builds `Solum-ref` from `PINNED_VERSIONS.txt`. Sibling / H3 are a **different** binary and must be labelled as such. |
| **Base images** | Do not introduce `:latest`. Pin `python:3.12-slim-bookworm`, `rust:1.91.1-bookworm`, `debian:bookworm-slim`. Digest-pin nginx. |
| **GitHub Actions** | Pin `actions/checkout` to a full commit SHA with a `# v4.x` comment. Dependabot is disabled; bump SHAs in a PR. |
| **Floating tags** | Do not introduce `:latest` for EHRbase, Postgres, nginx, Python, or Rust in paths that claim Stage-1 proofs. |

## Current pins (compose)

| Image | Pin |
|-------|-----|
| nginx | `1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10` |
| Python harness | `python:3.12-slim-bookworm` |
| Rust builder | `rust:1.91.1-bookworm` |
| Sidecar runtime | `debian:bookworm-slim` |
| EHRbase Postgres | `ehrbase/ehrbase-v2-postgres:16.2` |
| EHRbase | `ehrbase/ehrbase:2.34.0` |

## Review

Dependabot version updates are **disabled**. Image and Action bumps are manual PRs. Org hygiene: [MONTHLY-DEPENDENCY-HYGIENE](https://github.com/SynapticFour/synapticfour-infra/blob/main/docs/MONTHLY-DEPENDENCY-HYGIENE.md) when that repo is in scope.

# Contributing to Solum-Demo

## Process

- **No direct pushes to `main`.** Open a pull request. In GitHub → Settings → Branches, protect `main`:
  - Require status checks: `check` (workflow `smoke-syntax`) and `stage1` (workflow `smoke-stage1`)
  - Require branches to be up to date
  - Do not allow force pushes
- One human review is required when a second maintainer exists. Until then, the PR still exists so CI runs **before** merge, not after.
- Do not skip hooks.

## What this repo is

Local developer walkthrough of Solum Stage-1. **Not** a customer evaluation. See [docs/adr/0001-demo-scope.md](docs/adr/0001-demo-scope.md) and [docs/COVERAGE.md](docs/COVERAGE.md).

## Checks before merge

```bash
make check          # pin drift, LICENSE, bash -n, harness unit tests
make up             # or up-sibling
make smoke-ci       # consent then stage1 (tamper last)
```

Sibling/H3 proofs: `make smoke-all` (skips are failures).

## Honesty rules

- Do not claim physician/intern RBAC. Empty `capability[]` deny is the claim.
- Do not claim dual-write writes EHRbase compositions. `link_cdr=true` is refused.
- Do not leave `docs/COVERAGE.md` describing a workflow that does not exist.
- Bumping Solum: change `Solum-ref` in `PINNED_VERSIONS.txt` **and** the default ref in `Dockerfile` / `docker-compose.yml` (CI asserts they match). Prefer the Solum git tag (`v0.1.0`). The peel must equal Solum `docs/BASELINE.md` Verified commit, or the pin comment must say it does not.

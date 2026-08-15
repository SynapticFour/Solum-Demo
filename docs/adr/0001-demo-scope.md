# ADR 0001 — Demo scope: developer walkthrough, not customer evaluation

**Date:** 2026-08-15  
**Status:** Accepted

## Context

Solum-Demo exists so a developer can run Solum Stage-1 HTTP proofs locally (consent-gated crypto, empty-`capability[]` deny, hash-chained audit, HELIOS-oriented export envelope) and optional Track B / profile smokes against a sibling checkout.

Solum `config/profiles/dev-local.toml` permits ephemeral keys and client-asserted `capability[]`. The same file states that posture must not be used for customer evaluations. Pilot profiles (`eu-ehds`, `kenya-dpa`) require org-IAM.

## Decision

1. This repository is a **local developer walkthrough**. It is not a customer evaluation kit and must not be presented as one.
2. Stage-1 stays on `dev-local` + `--ephemeral`. Org-IAM / JWT is out of scope here; that proof lives in Solum tests and Showcase.
3. UI and README name `capability[]` as client-asserted. They do not invent physician/intern RBAC.
4. Three binaries are allowed and must stay labelled: Stage-1 **pin**, Stage-1 **sibling**, H3 **sibling**.
5. Host ports bind `127.0.0.1`. nginx injects the sidecar token; the dashboard JS must not contain it.

## Consequences

Customer-facing evaluations must use a Solum pilot profile with org-IAM, not this Compose file. Dual-write in `smoke-h3` proves the façade and the refuse-example-CDR contract, not a live EHR Prefer cut-over.

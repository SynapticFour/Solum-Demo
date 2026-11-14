# What a run shows

`make up` starts the laptop stack from the Solum tag in [PINNED_VERSIONS.txt](../PINNED_VERSIONS.txt). `make smoke-ci` then runs `make smoke-consent` and `make smoke-stage1`.

## What a successful run demonstrates

- The dashboard answers on `http://127.0.0.1:8080` (loopback only). If that port is taken, `SOLUM_DEMO_PORT` moves it.
- `make smoke-consent` prints `PASS consent`. The script records a grant, reads status `granted`, encrypts and decrypts a field, revokes the grant, and then refuses decrypt. The audit export after that refusal contains `consent.denied`.
- `make smoke-stage1` prints `PASS stage1`. The audit export's `format` starts with `solum-audit-helios`. An encrypt call with an empty capability list returns HTTP 403 and the export contains `access.denied`. The demo harness then rewrites `audit.jsonl`, and verify reports the chain broken.

The posture is Solum's `dev-local` profile: ephemeral keys, and a capability list sent by the caller. Solum's pilot profiles forbid that posture for a customer evaluation.

## What a run does not show

- A customer evaluation, a hospital role model, or organisation sign-in. Those are in Solum's tests and in [SynapticFour-Showcase](https://github.com/SynapticFour/SynapticFour-Showcase), not in this Compose file.
- Live HELIOS signing. The export is an envelope. [HELIOS](https://github.com/SynapticFour/HELIOS) is a separate program.
- A certificate, a clinical pilot, or a production Kenya, Nigeria, or South Africa system.
- That Solum's default branch is the pinned tag. The pin is v0.1.0. Solum's default branch is newer.
- Track B, the FHIR export, or the migration rehearsal. Those are `make smoke-h3`, `make smoke-fhir-ips`, and `make smoke-migration`, and they need a sibling Solum checkout. They are not `make smoke-ci`.

A green `make smoke-ci` is a technical signal for this pinned tag on a laptop. It is not a certificate and not a clinical pilot.

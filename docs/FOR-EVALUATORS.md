# For evaluators

No public status is recorded for this demonstration. It is a laptop walkthrough of a pinned Solum tag, not a product stage of its own.

## What to read after a run

1. The lines `PASS consent` and `PASS stage1` from `make smoke-ci`.
2. [WHAT-A-RUN-SHOWS.md](WHAT-A-RUN-SHOWS.md)
3. [COVERAGE.md](COVERAGE.md) and [PERSONA.md](PERSONA.md)

A green `make smoke-ci` is the Stage-1 consent and audit smoke on the pinned tag. It is not a certificate and not a clinical pilot. The stack uses `dev-local` (ephemeral keys and a caller-supplied capability list). Solum's pilot profiles refuse that posture for a customer evaluation.

## Pin

`make up` follows Solum tag **v0.1.0**, commit `b68a941ff1cc9a2406f25b27fed8f12368ebbf1b`, in [PINNED_VERSIONS.txt](../PINNED_VERSIONS.txt). The same tag is the default `SOLUM_REF` in the `Dockerfile` and in `docker-compose.yml`. The pin is not a statement that Solum's default branch is v0.1.0. Solum's default branch is newer. `make up-sibling` builds a local Solum checkout and is a different binary.

## Security of the demo posture

Host ports bind `127.0.0.1`. The sidecar token is written to a gitignored `.env` and injected by nginx. The dashboard source does not contain it. Ephemeral keys and plaintext HTTP inside the Compose network are for this walkthrough. Do not copy this Compose posture to a hospital network. Reporting an issue in this repository: [SECURITY.md](../SECURITY.md).

Contact: [contact@synapticfour.com](mailto:contact@synapticfour.com)

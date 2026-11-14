# Solum Demo

This demonstration runs a pinned Solum on a laptop so a person can see Stage-1 consent, an access check, and an audit log finish on that machine.

For a manufacturer or an engineer who wants to watch that path, and for someone judging what the run is evidence of.

**Status: No public status is recorded** for this demonstration. It follows [Solum](https://github.com/SynapticFour/Solum) at pin **v0.1.0** (`b68a941ff1cc9a2406f25b27fed8f12368ebbf1b` in [PINNED_VERSIONS.txt](PINNED_VERSIONS.txt)). The pin is not a statement that Solum's default branch is v0.1.0. Solum's default branch is newer.

## What a run shows

- A successful `make up` serves the dashboard at `http://127.0.0.1:8080` (loopback only).
- `make smoke-ci` prints `PASS consent` and then `PASS stage1`: a grant, a field check, an empty capability list refused with HTTP 403, and a tampered log reported as a broken chain.
- The audit export's `format` starts with `solum-audit-helios`. That is an envelope. This demo does not perform live HELIOS signing.

## What a run does not show

- A customer evaluation. The stack uses Solum `dev-local.toml` (ephemeral keys and a capability list sent by the caller). Solum's pilot profiles forbid that posture for customer evaluations.
- Organisation sign-in, a hospital role model, Track B, or a live clinical record. Persona: [docs/PERSONA.md](docs/PERSONA.md).
- A green run is a technical signal for this pinned tag. It is not a certificate and not a clinical pilot.

## Quick start

Prerequisites: Docker, `git`, `make`, `bash`, `python3`, and `curl`. A cold build compiles the pinned Solum sidecar and needs a network. The first build takes several minutes.

```bash
make up
make smoke-ci
```

`make up` reads `Solum-ref` from [PINNED_VERSIONS.txt](PINNED_VERSIONS.txt). You should see the dashboard answer at `http://127.0.0.1:8080`. `make smoke-ci` should print `PASS consent` and then `PASS stage1`. If port 8080 is taken, `SOLUM_DEMO_PORT=8088 make up`. Stop with `make down`. Wipe volumes with `make reset`.

`make prove` stays inside this repository: pin drift, the licence file, shell syntax, and the harness unit tests. You should see `Solum-Demo offline prove OK. Interactive: make up && make smoke-ci`.

A path that builds a sibling checkout instead of the pin: `make up-sibling`, with [Solum](https://github.com/SynapticFour/Solum) beside this clone. That binary is not the Stage-1 pin.

## Documentation

### Tutorial

- [Getting started](docs/GETTING-STARTED.md)

### How-to guides

- [Image pin](docs/IMAGE-PIN-POLICY.md)
- Pin file: [PINNED_VERSIONS.txt](PINNED_VERSIONS.txt)

### Reference

- [Coverage](docs/COVERAGE.md)

### Explanation

- [What a run shows](docs/WHAT-A-RUN-SHOWS.md)
- [For evaluators](docs/FOR-EVALUATORS.md)
- [Persona](docs/PERSONA.md)
- [Demo scope](docs/adr/0001-demo-scope.md)
- The full index is [docs/README.md](docs/README.md).

## Licence

This repository is Apache License 2.0. The file is [LICENSE](LICENSE). The Solum binary that `make up` compiles remains Business Source License 1.1. See [NOTICE](NOTICE).

## Website

- Product page: [https://synapticfour.com/en/solum/](https://synapticfour.com/en/solum/)
- Technical profile: [https://synapticfour.com/en/technical/solum/](https://synapticfour.com/en/technical/solum/)

The same pages exist in German (`/de/solum/`, `/de/technik/solum/`) and in French (`/fr/solum/`, `/fr/technique/solum/`).

The map of repositories: [profile/README.md](https://github.com/SynapticFour/.github/blob/main/profile/README.md).

Contact: [contact@synapticfour.com](mailto:contact@synapticfour.com)

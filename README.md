# Solum Demo

**Reference / demo** — not a product, not a customer evaluation, not a production environment. Local developer walkthrough of [Solum](https://github.com/SynapticFour/Solum).

Uses Solum `dev-local.toml` (ephemeral keys; client-asserted `capability[]`). Solum’s own profile forbids that posture for customer evaluations. Pilot org-IAM lives in Solum tests / Showcase, not here. Persona: [`docs/PERSONA.md`](docs/PERSONA.md).

> Audit export is a **HELIOS-oriented envelope** only — this demo does **not** perform live HELIOS signing.

## Ferrum / GA4GH suite

These ten public repositories are from the same organisation and can be composed. They are not a fifth product and not a bundle SKU. Each repository keeps its own version and license. Roles, maturity, and who consumes whom: [SUITE-OVERVIEW](https://github.com/SynapticFour/Ferrum/blob/main/docs/SUITE-OVERVIEW.md).

## Quick start

```bash
make up          # Solum-ref=v0.1.0 from PINNED_VERSIONS.txt
make smoke-ci    # smoke-consent then smoke-stage1 (tamper last)
```

UI: http://127.0.0.1:8080 (loopback only). Sibling Solum tree: `make up-sibling`. If `:8080` is taken: `SOLUM_DEMO_PORT=8088 make up`. Stop: `make down`. Wipe volumes: `make reset`.

## Documentation

- [Getting started](docs/GETTING-STARTED.md)
- [Persona](docs/PERSONA.md) · [Coverage](docs/COVERAGE.md)

## License

Apache License 2.0 — see [LICENSE](LICENSE). Solum itself is BUSL-1.1.

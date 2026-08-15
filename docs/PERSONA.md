# Persona — clinic Stage-1 consent / audit smoke

**Who this demo is for:** a clinic / HMIS engineer who wants to **see** empty-`capability[]` deny, consent-gated crypto, and a tamper-evident audit on a laptop.

This is **not** a customer evaluation of Solum. Stage-1 uses `dev-local.toml` (ephemeral keys, client-asserted `capability[]`). Solum’s own profile forbids that posture for customer evaluations. Coverage: [COVERAGE.md](COVERAGE.md). Product claims: Solum [CLAIMS-PROOF-TRAIL.md](https://github.com/SynapticFour/Solum/blob/main/docs/CLAIMS-PROOF-TRAIL.md).

## One command they should run

```bash
make up          # PINNED_VERSIONS.txt Solum-ref
make smoke-ci    # consent then stage1 (tamper last)
```

Pin: Solum SHA in [`PINNED_VERSIONS.txt`](../PINNED_VERSIONS.txt) must match Solum [BASELINE.md](https://github.com/SynapticFour/Solum/blob/main/docs/BASELINE.md) **Verified commit**. Sibling HEAD (`make up-sibling`) is a **different binary**.

## What ran vs what did not (honest sheet)

| Question they will ask | After `make smoke-ci` on the pin? | Evidence |
|------------------------|-----------------------------------|----------|
| Empty `capability[]` → 403 + `access.denied`? | Yes | Stage-1 / UI Scenario 1 — **not** hospital RBAC |
| Tamper of `audit.jsonl` → `chain_broken`? | Yes | Stage-1 / UI Scenario 2 |
| Grant → encrypt → decrypt → revoke → decrypt denied? | Yes | `make smoke-consent` |
| HELIOS **signed** the chain live? | **No** | Export envelope only (`format` starts with `solum-audit-helios`) |
| EHDS / MDR / TI / gematik certified? | **No** | Forbidden claim |
| Production Kenya / Nigeria / SA system of record? | **No** | Profile smokes are sibling Solum `check`, not this dashboard |
| Dual-write wrote a live EHR composition? | **No** | `link_cdr=true` is refused (`dead_lettered`) |
| Org-IAM / physician vs intern roles? | **No** | Showcase / Solum tests |
| Ferrum DRS/WES 403 after consent revoke? | **No** | Showcase `make h21-teeth` |

H3 / FHIR IPS / migration / claims-proof stay local (`make smoke-all`). Default GitHub Actions: syntax + Stage-1 Docker smoke — not EHRbase.

## Where the other personas go

| Persona | Repo |
|---------|------|
| Institute GA4GH pipeline | [Ferrum-GA4GH-Demo PERSONA](https://github.com/SynapticFour/Ferrum-GA4GH-Demo/blob/main/docs/PERSONA.md) |
| Composition + evidence pack | [Showcase persona-evidence](https://github.com/SynapticFour/SynapticFour-Showcase/blob/main/docs/for-customers/persona-evidence.md) |
| Audit signing without a pipeline | HELIOS `make prove` |

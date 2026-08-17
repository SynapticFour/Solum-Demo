# Getting started

```bash
git clone https://github.com/SynapticFour/Solum-Demo.git
cd Solum-Demo
make up
make smoke-ci
```

`make up` uses Solum-ref from [PINNED_VERSIONS.txt](../PINNED_VERSIONS.txt) (the tag must exist on origin). Cold build compiles `solum-sidecar` from that commit (Rust + libsodium); expect several minutes once.

While developing Solum beside this repo:

```bash
make up-sibling
make smoke-ci
```

Port conflict with Ferrum gateway:

```bash
SOLUM_DEMO_PORT=8088 make up
SOLUM_DEMO_PORT=8088 make smoke-ci
```

`make check` / `make prove`: pin drift, LICENSE, bash -n, harness unit tests. H3 CDR smoke: `make up-h3` then `make smoke-h3`. Full map: [COVERAGE.md](COVERAGE.md).

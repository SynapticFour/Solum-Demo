# Getting started

Prerequisites: Docker, `git`, `make`, `bash`, `python3`, and `curl`. A cold `make up` clones the pinned Solum tag and compiles `solum-sidecar` (Rust and libsodium inside the image). That build needs a network and takes several minutes the first time.

```bash
git clone https://github.com/SynapticFour/Solum-Demo.git
cd Solum-Demo
make up
make smoke-ci
```

`make up` uses Solum-ref from [PINNED_VERSIONS.txt](../PINNED_VERSIONS.txt) (the tag must exist on origin). You should see the dashboard answer at `http://127.0.0.1:8080` (loopback only). `make smoke-ci` should print `PASS consent` and then `PASS stage1`. Stop with `make down`.

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

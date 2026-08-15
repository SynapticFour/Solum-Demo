# Builds solum-sidecar from a pinned Solum git commit (not floating main).
# Pin is documented in PINNED_VERSIONS.txt (Solum-ref) and must include
# consent-gated crypto (subject/purpose on encrypt/decrypt) plus GET
# /v1/audit/* capability checks (X-Solum-Actor / X-Solum-Capability).
#
# Local sibling alternative: make up-sibling (Dockerfile.sibling + ../Solum).

ARG SOLUM_REF=6b4519c98f5c1e905ab5cf3f517787021d1e2604
ARG RUST_VERSION=1.91.1

FROM rust:${RUST_VERSION}-bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        libsodium-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

ARG SOLUM_REF
WORKDIR /build

# Fetch the exact commit (works for annotated tags and bare SHAs).
RUN git init \
    && git remote add origin https://github.com/SynapticFour/Solum.git \
    && git fetch --depth 1 origin "${SOLUM_REF}" \
    && git checkout FETCH_HEAD

# ferrum-core (and transitively Crypt4GH) resolve over the network at build time.
RUN cargo build --release -p solum-sidecar \
    && strip target/release/solum-sidecar

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libsodium23 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --home /nonexistent --shell /usr/sbin/nologin solum

COPY --from=builder /build/target/release/solum-sidecar /usr/local/bin/solum-sidecar
COPY --from=builder /build/config/profiles/dev-local.toml /etc/solum/dev-local.toml

RUN mkdir -p /data && chown solum:solum /data

USER solum
WORKDIR /data

ENV SOLUM_PROFILE=/etc/solum/dev-local.toml \
    SOLUM_AUDIT=/data/audit.jsonl \
    SOLUM_CONSENT_STORE=/data/consent.jsonl \
    SOLUM_SIDECAR_BIND=0.0.0.0:8787 \
    SOLUM_ALLOW_EPHEMERAL=1 \
    RUST_LOG=info

EXPOSE 8787

# Token must be supplied via compose/env (SOLUM_SIDECAR_TOKEN).
# --ephemeral is intentional for this local demo only — see README.
ENTRYPOINT ["solum-sidecar"]
CMD ["--ephemeral", "--bind", "0.0.0.0:8787"]

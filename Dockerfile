# Builds solum-sidecar from the verified Solum baseline tag only.
# Reproducibility: never track Solum main — pin the same Stage-1 custody tag
# used across the Solum session.
#
# Multi-stage: compile in Rust builder, ship a slim runtime with the binary
# and the demo profile (dev-local.toml) copied from that same tag.

ARG SOLUM_TAG=stage1-baseline-sidecar-custody-2026-08-01
ARG RUST_VERSION=1.91.1

FROM rust:${RUST_VERSION}-bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        libsodium-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

ARG SOLUM_TAG
WORKDIR /build

# Shallow clone of the exact annotated/lightweight tag for a reproducible tree.
RUN git clone --depth 1 --branch "${SOLUM_TAG}" \
    https://github.com/SynapticFour/Solum.git .

# ferrum-core (and transitively Crypt4GH) resolve over the network at build time.
RUN cargo build --release -p solum-sidecar \
    && strip target/release/solum-sidecar

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
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

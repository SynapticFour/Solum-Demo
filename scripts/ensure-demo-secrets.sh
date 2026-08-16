#!/usr/bin/env bash
# Mint a loopback-only sidecar token into .env. Refuse the old shared default.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEFAULT='solum-demo-local-token-not-for-production'

if [ -f .env ] && grep -Fq "$DEFAULT" .env; then
  echo "Refusing $DEFAULT in .env — delete it and re-run make up." >&2
  exit 1
fi

if [ -z "${SOLUM_SIDECAR_TOKEN:-}" ]; then
  if [ -f .env ] && grep -Eq '^SOLUM_SIDECAR_TOKEN=.+' .env; then
    :
  else
    TOKEN="$(openssl rand -hex 24)"
    printf 'SOLUM_SIDECAR_TOKEN=%s\n' "$TOKEN" >>.env
    echo "Wrote SOLUM_SIDECAR_TOKEN to .env (gitignored)."
  fi
else
  if [ "$SOLUM_SIDECAR_TOKEN" = "$DEFAULT" ]; then
    echo "Refusing default SOLUM_SIDECAR_TOKEN." >&2
    exit 1
  fi
  if [ ! -f .env ] || ! grep -Eq '^SOLUM_SIDECAR_TOKEN=.+' .env; then
    printf 'SOLUM_SIDECAR_TOKEN=%s\n' "$SOLUM_SIDECAR_TOKEN" >>.env
  fi
fi

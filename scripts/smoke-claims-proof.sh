#!/usr/bin/env bash
# One-shot: Solum claims proof trail via sibling checkout
# (Track A CLI + FHIR structural + Kenya). Soft-skip if ../Solum missing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOLUM_ROOT="${SOLUM_ROOT:-$ROOT/../Solum}"
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-claims-proof}"
REQUIRE="${SOLUM_DEMO_CLAIMS_REQUIRE:-0}"
mkdir -p "$OUT"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }

[[ -f "$SOLUM_ROOT/scripts/demo-claims-proof.sh" ]] || skip "Solum claims proof script not at $SOLUM_ROOT"
SOLUM_ROOT="$(cd "$SOLUM_ROOT" && pwd)"

chmod +x "$SOLUM_ROOT/scripts/demo-claims-proof.sh" 2>/dev/null || true
if ! (cd "$SOLUM_ROOT" && ./scripts/demo-claims-proof.sh) >"$OUT/claims-proof.log" 2>&1; then
  fail "demo-claims-proof.sh failed — see $OUT/claims-proof.log"
fi
echo "PASS claims-proof" | tee "$OUT/result.txt"
exit 0

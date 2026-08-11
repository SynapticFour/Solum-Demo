#!/usr/bin/env bash
# Wrap Solum migration Prefer/Cut-over dry rehearsal tooling.
# Soft-skip if ../Solum missing unless SOLUM_DEMO_MIGRATION_REQUIRE=1.
# Aligns with Solum claim A15 (tooling only — not live partner cut-over).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOLUM_ROOT="${SOLUM_ROOT:-$ROOT/../Solum}"
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-migration}"
REQUIRE="${SOLUM_DEMO_MIGRATION_REQUIRE:-0}"
mkdir -p "$OUT"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }

[[ -x "$SOLUM_ROOT/scripts/migration-rehearsal-dry-run.sh" ]] \
  || [[ -f "$SOLUM_ROOT/scripts/migration-rehearsal-dry-run.sh" ]] \
  || skip "Solum migration rehearsal script not at $SOLUM_ROOT"
SOLUM_ROOT="$(cd "$SOLUM_ROOT" && pwd)"

export SOLUM_MIGRATION_REHEARSAL_OUT="$OUT/rehearsal"
chmod +x "$SOLUM_ROOT/scripts/migration-rehearsal-dry-run.sh" 2>/dev/null || true
if ! (cd "$SOLUM_ROOT" && ./scripts/migration-rehearsal-dry-run.sh) >"$OUT/rehearsal.log" 2>&1; then
  fail "migration rehearsal failed — see $OUT/rehearsal.log"
fi
echo "OK: migration dry rehearsal" | tee -a "$OUT/result.txt"
echo "PASS migration-rehearsal" | tee "$OUT/result.txt"
exit 0

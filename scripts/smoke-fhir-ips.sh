#!/usr/bin/env bash
# Wrap Solum IPS structural export (+ optional HL7 Validator if JAR set).
# Soft-skip if ../Solum missing unless SOLUM_DEMO_FHIR_REQUIRE=1.
# Aligns with Solum claims A9 / A10.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOLUM_ROOT="${SOLUM_ROOT:-$ROOT/../Solum}"
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-fhir-ips}"
REQUIRE="${SOLUM_DEMO_FHIR_REQUIRE:-0}"
mkdir -p "$OUT"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

[[ -d "$SOLUM_ROOT/crates/fhir" ]] || skip "Solum checkout not at $SOLUM_ROOT"
SOLUM_ROOT="$(cd "$SOLUM_ROOT" && pwd)"

BUNDLE="$OUT/patient-summary-bundle.json"
(cd "$SOLUM_ROOT" && cargo run -q -p solum-core -- fhir export-ips --out "$BUNDLE") \
  >"$OUT/export-ips.log" 2>&1 \
  || fail "solum fhir export-ips failed — see $OUT/export-ips.log"
ok "solum fhir export-ips wrote bundle"

# Reuse Solum structural validator (writes under Solum example out unless overridden)
export SOLUM_FHIR_OUT="$OUT"
if ! (cd "$SOLUM_ROOT" && ./scripts/validate-fhir-ips.sh) >"$OUT/validate.log" 2>&1; then
  # validate-fhir-ips may soft-skip JAR; structural failure is hard
  if grep -q '^FAIL' "$OUT/structural-check.txt" 2>/dev/null; then
    fail "structural FHIR checks failed — see $OUT/structural-check.txt"
  fi
  # If script itself failed for other reasons:
  if ! grep -q 'structural checks' "$OUT/validate.log"; then
    fail "validate-fhir-ips.sh failed — see $OUT/validate.log"
  fi
fi
ok "FHIR IPS structural path ran (see $OUT/validate.log)"
echo "PASS fhir-ips" | tee "$OUT/result.txt"
exit 0

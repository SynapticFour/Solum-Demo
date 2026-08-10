#!/usr/bin/env bash
# Profile refuse smoke via sibling Solum checkout (kenya-dpa / eu-ehds).
# Soft-skip if ../Solum missing unless SOLUM_DEMO_PROFILE_REQUIRE=1.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOLUM_ROOT="${SOLUM_ROOT:-$ROOT/../Solum}"
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-profile}"
REQUIRE="${SOLUM_DEMO_PROFILE_REQUIRE:-0}"
mkdir -p "$OUT"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

[[ -d "$SOLUM_ROOT/config/profiles" ]] || skip "Solum checkout not at $SOLUM_ROOT"
SOLUM_ROOT="$(cd "$SOLUM_ROOT" && pwd)"

check_ok() {
  local profile="$1" region="$2" log="$3"
  if (cd "$SOLUM_ROOT" && SOLUM_STORAGE_REGION="$region" cargo run -q -p solum-core -- check --profile "config/profiles/$profile") >"$log" 2>&1; then
    return 0
  fi
  return 1
}

check_ok kenya-dpa.toml KE "$OUT/kenya-ke.txt" || fail "kenya-dpa + KE should pass — see $OUT/kenya-ke.txt"
ok "kenya-dpa + KE starts"

if check_ok kenya-dpa.toml EU "$OUT/kenya-eu.txt"; then
  fail "kenya-dpa + EU must refuse"
fi
ok "kenya-dpa + EU refused"

check_ok eu-ehds.toml EU "$OUT/eu-eu.txt" || fail "eu-ehds + EU should pass — see $OUT/eu-eu.txt"
ok "eu-ehds + EU starts"

if check_ok eu-ehds.toml us-east-1 "$OUT/eu-us.txt"; then
  fail "eu-ehds + us-east-1 must refuse"
fi
ok "eu-ehds + us-east-1 refused"

echo "PASS profile-refuse" | tee "$OUT/result.txt"
exit 0

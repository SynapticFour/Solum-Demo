#!/usr/bin/env bash
# Profile refuse + Kenya transfer fail-closed (sibling Solum).
# Skip is a failure unless SOLUM_DEMO_ALLOW_SKIP=1 or SOLUM_DEMO_PROFILE_REQUIRE=0.
# Aligns with Solum claims A7 / A8.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-smoke.sh
source "$ROOT/scripts/lib-smoke.sh"
SOLUM_ROOT="${SOLUM_ROOT:-$ROOT/../Solum}"
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-profile}"
REQUIRE="$(solum_demo_require "${SOLUM_DEMO_PROFILE_REQUIRE:-}")"
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

# Ephemeral custody refused by kenya-dpa
if (cd "$SOLUM_ROOT" && SOLUM_STORAGE_REGION=KE SOLUM_KEY_CUSTODY=ephemeral_test \
  cargo run -q -p solum-core -- check --profile config/profiles/kenya-dpa.toml) >"$OUT/kenya-ephemeral.txt" 2>&1; then
  fail "kenya-dpa must refuse ephemeral_test custody"
fi
ok "kenya-dpa + ephemeral refused"

# Empty permitted_destinations fail-closed (unit)
(cd "$SOLUM_ROOT" && cargo test -q -p solum-profiles kenya_validate_transfer_fail_closed_empty_destinations) \
  >"$OUT/kenya-transfer.txt" 2>&1 \
  || fail "kenya transfer fail-closed unit — see $OUT/kenya-transfer.txt"
ok "kenya transfer destinations fail-closed (unit)"

# Planned NG/SA scaffolds exist and are NOT auto-loaded from config/profiles/
[[ -f "$SOLUM_ROOT/config/profiles/planned/nigeria-ndpa.toml" ]] \
  || fail "missing planned nigeria-ndpa.toml"
[[ -f "$SOLUM_ROOT/config/profiles/planned/south-africa-popia.toml" ]] \
  || fail "missing planned south-africa-popia.toml"
if ls "$SOLUM_ROOT/config/profiles/"nigeria*.toml >/dev/null 2>&1; then
  fail "nigeria profile must stay under planned/ (not auto-loaded)"
fi
ok "Nigeria/SA remain planned scaffolds only (A13)"

check_ok eu-ehds.toml EU "$OUT/eu-eu.txt" || fail "eu-ehds + EU should pass — see $OUT/eu-eu.txt"
ok "eu-ehds + EU starts"

if check_ok eu-ehds.toml us-east-1 "$OUT/eu-us.txt"; then
  fail "eu-ehds + us-east-1 must refuse"
fi
ok "eu-ehds + us-east-1 refused"

echo "PASS profile-refuse" | tee "$OUT/result.txt"
exit 0

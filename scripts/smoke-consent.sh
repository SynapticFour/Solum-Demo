#!/usr/bin/env bash
# Track A consent grant → status → revoke (Stage-1 stack). Complements UI (crypto/audit only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:8080}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-consent}"
mkdir -p "$OUT"
SUBJECT="patient/demo-smoke"
PURPOSE="care_provision"

fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" "${HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || fail "sidecar not ready at $BASE — run: make up"

grant="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/consent/grant" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:consent:grant\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"scope\":[\"patient_summary\"]}")"
gbody="$(echo "$grant" | sed '$d')"
gcode="$(echo "$grant" | tail -n1)"
echo "$gbody" >"$OUT/grant.json"
[[ "$gcode" == "200" || "$gcode" == "201" ]] || fail "consent grant expected 200/201 got $gcode: $gbody"
ok "consent grant"

status="$(curl -sS "${HDR[@]}" "$BASE/v1/consent/status?subject=$SUBJECT&purpose=$PURPOSE")"
echo "$status" >"$OUT/status-granted.json"
echo "$status" | grep -qi '"status"[[:space:]]*:[[:space:]]*"granted"' || fail "expected status=granted: $status"
ok "consent status granted"

revoke="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/consent/revoke" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:consent:revoke\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\"}")"
rbody="$(echo "$revoke" | sed '$d')"
rcode="$(echo "$revoke" | tail -n1)"
echo "$rbody" >"$OUT/revoke.json"
[[ "$rcode" == "200" || "$rcode" == "201" ]] || fail "consent revoke expected 200/201 got $rcode: $rbody"

status2="$(curl -sS "${HDR[@]}" "$BASE/v1/consent/status?subject=$SUBJECT&purpose=$PURPOSE")"
echo "$status2" >"$OUT/status-revoked.json"
echo "$status2" | grep -Eqi '"status"[[:space:]]*:[[:space:]]*"(revoked|unknown)"' || fail "expected revoked/unknown: $status2"
ok "consent revoke reflected"
echo "PASS consent" | tee "$OUT/result.txt"
exit 0

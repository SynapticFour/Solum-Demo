#!/usr/bin/env bash
# Track A consent + Deny B: grant → encrypt → decrypt → revoke → decrypt refuse.
# Aligns with Solum claims A1-lite (HTTP) / A3 (consent.denied after revoke).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:8080}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-consent}"
mkdir -p "$OUT"
SUBJECT="patient/demo-smoke"
PURPOSE="care_provision"
KEY_REF="ephemeral/demo-consent"

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

enc="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/encrypt" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:crypto:encrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"category\":\"patient_summary\",\"plaintext_base64\":\"ZGVuaS1i\",\"key_ref\":\"$KEY_REF\"}")"
ebody="$(echo "$enc" | sed '$d')"
ecode="$(echo "$enc" | tail -n1)"
echo "$ebody" >"$OUT/encrypt.json"
[[ "$ecode" == "200" ]] || fail "encrypt after grant expected 200 got $ecode: $ebody"
ok "encrypt after grant"

# Extract field JSON for decrypt (jq optional — use python)
FIELD_JSON="$(python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["field"]))' <<<"$ebody")" \
  || fail "encrypt response missing field"

dec_ok="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/decrypt" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:crypto:decrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"key_ref\":\"$KEY_REF\",\"field\":$FIELD_JSON}")"
dbody="$(echo "$dec_ok" | sed '$d')"
dcode="$(echo "$dec_ok" | tail -n1)"
echo "$dbody" >"$OUT/decrypt-ok.json"
[[ "$dcode" == "200" ]] || fail "decrypt while granted expected 200 got $dcode: $dbody"
ok "decrypt while granted"

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

# Deny B: decrypt after revoke must fail (HTTP 400 + consent denied message) and audit
dec_deny="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/decrypt" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:crypto:decrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"key_ref\":\"$KEY_REF\",\"field\":$FIELD_JSON}")"
ddbody="$(echo "$dec_deny" | sed '$d')"
ddcode="$(echo "$dec_deny" | tail -n1)"
echo "$ddbody" >"$OUT/decrypt-after-revoke.json"
[[ "$ddcode" != "200" ]] || fail "decrypt after revoke must not succeed: $ddbody"
echo "$ddbody" | grep -qi 'consent' || fail "expected consent denial message: $ddbody"
ok "Deny B — decrypt refused after revoke (HTTP $ddcode)"

export_json="$(curl -sS "${HDR[@]}" "$BASE/v1/audit/export")"
echo "$export_json" >"$OUT/audit-export.json"
echo "$export_json" | grep -q 'consent.denied' \
  || fail "audit export missing consent.denied after Deny B"
ok "consent.denied audited"

echo "PASS consent" | tee "$OUT/result.txt"
exit 0

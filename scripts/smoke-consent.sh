#!/usr/bin/env bash
# Track A consent + Deny B: grant → encrypt → decrypt → revoke → decrypt refuse.
# Aligns with Solum claims A1-lite (HTTP) / A3 (consent.denied after revoke).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-smoke.sh
source "$ROOT/scripts/lib-smoke.sh"
BASE="${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:8080}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
GET_HDR=(
  -H "X-Solum-Sidecar-Token: $TOKEN"
  -H "X-Solum-Actor: practitioner/smoke"
  -H "X-Solum-Capability: solum:audit:export,solum:audit:verify,solum:consent:read"
)
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-consent}"
mkdir -p "$OUT"
SUBJECT="patient/demo-smoke"
PURPOSE="care_provision"
KEY_REF="ephemeral/demo-consent"

fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" "${GET_HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || fail "sidecar not ready at $BASE — run: make up"

gcode="$(curl_json "$OUT/grant.json" POST "$BASE/v1/consent/grant" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:consent:grant\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"scope\":[\"patient_summary\"]}")"
[[ "$gcode" == "200" || "$gcode" == "201" ]] || fail "consent grant expected 200/201 got $gcode: $(cat "$OUT/grant.json")"
ok "consent grant"

curl -sS "${GET_HDR[@]}" "$BASE/v1/consent/status?subject=$SUBJECT&purpose=$PURPOSE" \
  >"$OUT/status-granted.json"
assert_json "$OUT/status-granted.json" 'd.get("status") == "granted"' \
  || fail "expected status=granted: $(cat "$OUT/status-granted.json")"
ok "consent status granted"

ecode="$(curl_json "$OUT/encrypt.json" POST "$BASE/v1/crypto/encrypt" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:crypto:encrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"category\":\"patient_summary\",\"plaintext_base64\":\"ZGVuaS1i\",\"key_ref\":\"$KEY_REF\"}")"
[[ "$ecode" == "200" ]] || fail "encrypt after grant expected 200 got $ecode: $(cat "$OUT/encrypt.json")"
ok "encrypt after grant"

FIELD_JSON="$(python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["field"]))' <"$OUT/encrypt.json")" \
  || fail "encrypt response missing field"

dcode="$(curl_json "$OUT/decrypt-ok.json" POST "$BASE/v1/crypto/decrypt" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:crypto:decrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"key_ref\":\"$KEY_REF\",\"field\":$FIELD_JSON}")"
[[ "$dcode" == "200" ]] || fail "decrypt while granted expected 200 got $dcode: $(cat "$OUT/decrypt-ok.json")"
ok "decrypt while granted"

rcode="$(curl_json "$OUT/revoke.json" POST "$BASE/v1/consent/revoke" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:consent:revoke\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\"}")"
[[ "$rcode" == "200" || "$rcode" == "201" ]] || fail "consent revoke expected 200/201 got $rcode: $(cat "$OUT/revoke.json")"

curl -sS "${GET_HDR[@]}" "$BASE/v1/consent/status?subject=$SUBJECT&purpose=$PURPOSE" \
  >"$OUT/status-revoked.json"
assert_json "$OUT/status-revoked.json" 'd.get("status") in ("revoked", "unknown")' \
  || fail "expected revoked/unknown: $(cat "$OUT/status-revoked.json")"
ok "consent revoke reflected"

ddcode="$(curl_json "$OUT/decrypt-after-revoke.json" POST "$BASE/v1/crypto/decrypt" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/smoke\",\"capability\":[\"solum:crypto:decrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"key_ref\":\"$KEY_REF\",\"field\":$FIELD_JSON}")"
[[ "$ddcode" != "200" ]] || fail "decrypt after revoke must not succeed: $(cat "$OUT/decrypt-after-revoke.json")"
[[ "$ddcode" == "400" || "$ddcode" == "403" ]] \
  || fail "decrypt after revoke expected 400/403 got $ddcode: $(cat "$OUT/decrypt-after-revoke.json")"
python3 - "$OUT/decrypt-after-revoke.json" <<'PY' || fail "expected consent denial message"
import json, sys
d = json.load(open(sys.argv[1]))
msg = (d.get("message") or "").lower()
err = (d.get("error") or "").lower()
if "consent denied" not in msg and "consent.denied" not in msg and err != "consent.denied":
    sys.exit(1)
PY
ok "Deny B — decrypt refused after revoke (HTTP $ddcode)"

curl -sS "${GET_HDR[@]}" "$BASE/v1/audit/export" >"$OUT/audit-export.json"
python3 - "$OUT/audit-export.json" <<'PY' || fail "audit export missing consent.denied after Deny B"
import json, sys
d = json.load(open(sys.argv[1]))
types = [(r.get("event") or {}).get("event_type") for r in d.get("records") or []]
if "consent.denied" not in types:
    sys.exit(1)
PY
ok "consent.denied audited"

echo "PASS consent" | tee "$OUT/result.txt"
exit 0

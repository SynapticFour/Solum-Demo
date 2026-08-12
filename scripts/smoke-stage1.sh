#!/usr/bin/env bash
# Stage-1 smoke: consent-gated encrypt allow/deny + HELIOS envelope + audit tamper.
# Aligns with Solum claims A2 / A6 (authz deny + export envelope).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:8080}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-stage1}"
mkdir -p "$OUT"
SUBJECT="patient/demo-stage1"
PURPOSE="care_provision"

fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" "${HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || fail "sidecar not ready at $BASE (HTTP $code) — run: make up"

# HELIOS-oriented export envelope (not live signing)
export_json="$(curl -sS "${HDR[@]}" "$BASE/v1/audit/export")"
echo "$export_json" >"$OUT/audit-export.json"
echo "$export_json" | grep -q 'solum-audit-helios' \
  || fail "audit export missing solum-audit-helios* format marker"
ok "HELIOS-oriented audit export envelope present"

# Grant consent so capability-checked encrypt can succeed (Deny B prerequisite)
grant="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/consent/grant" \
  -d "{\"actor\":\"practitioner/amina\",\"capability\":[\"solum:consent:grant\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"scope\":[\"patient_summary\"]}")"
gbody="$(echo "$grant" | sed '$d')"
gcode="$(echo "$grant" | tail -n1)"
echo "$gbody" >"$OUT/consent-grant.json"
[[ "$gcode" == "200" || "$gcode" == "201" ]] || fail "consent grant expected 200/201 got $gcode: $gbody"
ok "consent grant for encrypt path"

# Allow encrypt (capability + consent + subject/purpose)
allow="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/encrypt" \
  -d "{\"actor\":\"practitioner/amina\",\"capability\":[\"solum:crypto:encrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"category\":\"patient_summary\",\"plaintext_base64\":\"SGVsbG8=\",\"key_ref\":\"ephemeral/demo\"}")"
abody="$(echo "$allow" | sed '$d')"
acode="$(echo "$allow" | tail -n1)"
echo "$abody" >"$OUT/encrypt-allow.json"
[[ "$acode" == "200" ]] || fail "encrypt allow expected 200 got $acode: $abody"
ok "encrypt allow HTTP 200"

# Deny encrypt (empty capabilities → authorization.denied)
deny="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/encrypt" \
  -d "{\"actor\":\"intern/x\",\"capability\":[],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"category\":\"patient_summary\",\"plaintext_base64\":\"SGVsbG8=\",\"key_ref\":\"ephemeral/demo\"}")"
dbody="$(echo "$deny" | sed '$d')"
dcode="$(echo "$deny" | tail -n1)"
echo "$dbody" >"$OUT/encrypt-deny.json"
[[ "$dcode" == "403" ]] || fail "encrypt deny expected 403 got $dcode: $dbody"
ok "encrypt deny HTTP 403"

# Confirm authorization.denied appears in audit export
export2="$(curl -sS "${HDR[@]}" "$BASE/v1/audit/export")"
echo "$export2" >"$OUT/audit-export-after-deny.json"
echo "$export2" | grep -q 'authorization.denied' \
  || fail "audit export missing authorization.denied after empty-capability encrypt"
ok "authorization.denied audited"

# Tamper via harness + verify
tamper="$(curl -sS -w "\n%{http_code}" -X POST "$BASE/demo/simulate-tampering" \
  -H "Content-Type: application/json" -d '{}')"
tbody="$(echo "$tamper" | sed '$d')"
tcode="$(echo "$tamper" | tail -n1)"
echo "$tbody" >"$OUT/tamper.json"
[[ "$tcode" == "200" ]] || fail "harness tamper expected HTTP 200 got $tcode: $tbody"
echo "$tbody" | grep -q '"ok"[[:space:]]*:[[:space:]]*true' \
  || fail "harness tamper did not report ok: $tbody"
# Require an actual mutation (or an already-tampered marker from a prior step).
echo "$tbody" | grep -Eq '"already_tampered"[[:space:]]*:[[:space:]]*true|"tampered_actor"' \
  || fail "harness tamper response missing mutation evidence: $tbody"
ok "harness mutated audit.jsonl on shared volume"

# Sidecar re-opens the file on each verify; brief retry covers volume visibility races.
verify_ok=0
vbody=""
vcode=""
for _try in 1 2 3 4 5; do
  verify="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" "$BASE/v1/audit/verify")"
  vbody="$(echo "$verify" | sed '$d')"
  vcode="$(echo "$verify" | tail -n1)"
  if echo "$vbody" | grep -qi "chain_broken\|broken\|error"; then
    verify_ok=1
    break
  fi
  sleep 0.4
done
echo "$vbody" >"$OUT/audit-verify.json"
[[ "$verify_ok" == "1" ]] || fail "expected chain_broken after tamper: $vbody"
ok "audit verify reports chain break (HTTP $vcode)"
echo "PASS stage1" | tee "$OUT/result.txt"
exit 0

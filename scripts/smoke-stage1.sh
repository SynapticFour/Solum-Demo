#!/usr/bin/env bash
# Stage-1 smoke: consent-gated encrypt allow/deny + HELIOS envelope + audit tamper.
# Aligns with Solum claims A2 / A6 (authz deny + export envelope).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-smoke.sh
source "$ROOT/scripts/lib-smoke.sh"
BASE="${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:8080}"
TOKEN="$(load_sidecar_token)"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
GET_HDR=(
  -H "X-Solum-Sidecar-Token: $TOKEN"
  -H "X-Solum-Actor: practitioner/amina"
  -H "X-Solum-Capability: solum:audit:export,solum:audit:verify,solum:consent:read"
)
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-stage1}"
mkdir -p "$OUT"
SUBJECT="patient/demo-stage1"
PURPOSE="care_provision"

fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" "${GET_HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || fail "sidecar not ready at $BASE (HTTP $code) — run: make up"

curl -sS "${GET_HDR[@]}" "$BASE/v1/audit/export" >"$OUT/audit-export.json"
assert_json "$OUT/audit-export.json" \
  'str(d.get("format") or "").startswith("solum-audit-helios")' \
  || fail "audit export missing solum-audit-helios* format marker"
ok "HELIOS-oriented audit export envelope present"

grant_code="$(curl_json "$OUT/consent-grant.json" POST "$BASE/v1/consent/grant" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/amina\",\"capability\":[\"solum:consent:grant\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"scope\":[\"patient_summary\"]}")"
[[ "$grant_code" == "200" || "$grant_code" == "201" ]] \
  || fail "consent grant expected 200/201 got $grant_code: $(cat "$OUT/consent-grant.json")"
ok "consent grant for encrypt path"

allow_code="$(curl_json "$OUT/encrypt-allow.json" POST "$BASE/v1/crypto/encrypt" "${HDR[@]}" \
  -d "{\"actor\":\"practitioner/amina\",\"capability\":[\"solum:crypto:encrypt\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"category\":\"patient_summary\",\"plaintext_base64\":\"SGVsbG8=\",\"key_ref\":\"ephemeral/demo\"}")"
[[ "$allow_code" == "200" ]] || fail "encrypt allow expected 200 got $allow_code: $(cat "$OUT/encrypt-allow.json")"
ok "encrypt allow HTTP 200"

deny_code="$(curl_json "$OUT/encrypt-deny.json" POST "$BASE/v1/crypto/encrypt" "${HDR[@]}" \
  -d "{\"actor\":\"intern/x\",\"capability\":[],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"category\":\"patient_summary\",\"plaintext_base64\":\"SGVsbG8=\",\"key_ref\":\"ephemeral/demo\"}")"
[[ "$deny_code" == "403" ]] || fail "encrypt deny expected 403 got $deny_code: $(cat "$OUT/encrypt-deny.json")"
assert_json "$OUT/encrypt-deny.json" 'd.get("error") == "forbidden"' \
  || fail "encrypt deny body must have error=forbidden"
ok "encrypt deny HTTP 403 (empty capability[] — client-asserted, not RBAC)"

curl -sS "${GET_HDR[@]}" "$BASE/v1/audit/export" >"$OUT/audit-export-after-deny.json"
python3 - "$OUT/audit-export-after-deny.json" <<'PY' || fail "audit export missing access.denied after empty-capability encrypt"
import json, sys
d = json.load(open(sys.argv[1]))
types = [(r.get("event") or {}).get("event_type") for r in d.get("records") or []]
# Product writes access.denied (solum_audit::events::ACCESS_DENIED). Older copy said authorization.denied.
if "access.denied" not in types and "authorization.denied" not in types:
    sys.exit(1)
PY
ok "access.denied audited"

tamper_code="$(curl_json "$OUT/tamper.json" POST "$BASE/demo/simulate-tampering" "${HDR[@]}" -d '{}')"
[[ "$tamper_code" == "200" ]] || fail "harness tamper expected HTTP 200 got $tamper_code: $(cat "$OUT/tamper.json")"
assert_json "$OUT/tamper.json" 'd.get("ok") is True' \
  || fail "harness tamper did not report ok"
assert_json "$OUT/tamper.json" 'd.get("already_tampered") is True or bool(d.get("tampered_actor"))' \
  || fail "harness tamper response missing mutation evidence"
ok "harness mutated audit.jsonl on shared volume"

verify_ok=0
vcode=""
for _try in 1 2 3 4 5; do
  vcode="$(curl_json "$OUT/audit-verify.json" GET "$BASE/v1/audit/verify" "${GET_HDR[@]}")"
  if python3 - "$OUT/audit-verify.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
err = d.get("error") or ""
msg = (d.get("message") or "").lower()
# Pin 6b4519c: FileAuditStore::open verifies the chain, so tamper fails open()
# and the sidecar maps that to error=bad_request with a "chain broken" message.
# verify_chain() itself would return error=chain_broken.
ok = err == "chain_broken" or "chain broken" in msg or "chain_broken" in msg
sys.exit(0 if ok else 1)
PY
  then
    verify_ok=1
    break
  fi
  sleep 0.4
done
[[ "$verify_ok" == "1" ]] || fail "expected chain-broken evidence after tamper: $(cat "$OUT/audit-verify.json")"
ok "audit verify reports chain broken (HTTP $vcode)"
echo "PASS stage1" | tee "$OUT/result.txt"
exit 0

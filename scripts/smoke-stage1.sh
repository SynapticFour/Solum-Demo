#!/usr/bin/env bash
# Stage-1 smoke: fail-closed encrypt + audit tamper verify (same proofs as UI / Showcase solum-stage).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:8080}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-stage1}"
mkdir -p "$OUT"

fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" "${HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || fail "sidecar not ready at $BASE (HTTP $code) — run: make up"

# Allow encrypt
allow="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/encrypt" \
  -d '{"actor":"practitioner/amina","capability":["solum:crypto:encrypt"],"category":"patient_summary","plaintext_base64":"SGVsbG8=","key_ref":"ephemeral/demo"}')"
abody="$(echo "$allow" | sed '$d')"
acode="$(echo "$allow" | tail -n1)"
echo "$abody" >"$OUT/encrypt-allow.json"
[[ "$acode" == "200" ]] || fail "encrypt allow expected 200 got $acode: $abody"
ok "encrypt allow HTTP 200"

# Deny encrypt
deny="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" -X POST "$BASE/v1/crypto/encrypt" \
  -d '{"actor":"intern/x","capability":[],"category":"patient_summary","plaintext_base64":"SGVsbG8=","key_ref":"ephemeral/demo"}')"
dbody="$(echo "$deny" | sed '$d')"
dcode="$(echo "$deny" | tail -n1)"
echo "$dbody" >"$OUT/encrypt-deny.json"
[[ "$dcode" == "403" ]] || fail "encrypt deny expected 403 got $dcode: $dbody"
ok "encrypt deny HTTP 403"

# Tamper via harness + verify
curl -sS -X POST "$BASE/demo/simulate-tampering" -H "Content-Type: application/json" -d '{}' \
  >"$OUT/tamper.json" || fail "harness tamper failed"
verify="$(curl -sS -w "\n%{http_code}" "${HDR[@]}" "$BASE/v1/audit/verify")"
vbody="$(echo "$verify" | sed '$d')"
vcode="$(echo "$verify" | tail -n1)"
echo "$vbody" >"$OUT/audit-verify.json"
echo "$vbody" | grep -qi "chain_broken\|broken\|error" || fail "expected chain_broken after tamper: $vbody"
ok "audit verify reports chain break (HTTP $vcode)"
echo "PASS stage1" | tee "$OUT/result.txt"
exit 0

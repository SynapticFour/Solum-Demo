#!/usr/bin/env bash
# H3 Track B smoke against sidecar-h3 (:8787) + EHRbase.
# Soft-skip (exit 0) when stack is down unless SOLUM_DEMO_H3_REQUIRE=1.
# Dual-write: façade persist (link_cdr=false) + example-CDR refuse (link_cdr=true → 202 dead-letter).
# This does NOT prove a live Prefer dual-write into EHRbase compositions.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-smoke.sh
source "$ROOT/scripts/lib-smoke.sh"
BASE="${SOLUM_H3_BASE_URL:-http://127.0.0.1:8787}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
GET_HDR=(
  -H "X-Solum-Sidecar-Token: $TOKEN"
  -H "X-Solum-Actor: practitioner/h3"
  -H "X-Solum-Capability: solum:audit:export,solum:cdr:read,solum:consent:read"
  -H "X-Solum-Subject: h3-demo-patient"
  -H "X-Solum-Purpose: care_provision"
)
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-h3}"
REQUIRE="${SOLUM_DEMO_H3_REQUIRE:-0}"
ACTOR='practitioner/h3'
SUBJECT='h3-demo-patient'
PURPOSE='care_provision'
mkdir -p "$OUT"
{
  echo "Solum-Demo smoke-h3"
  echo "utc: $(date -u +%Y%m%dT%H%M%SZ)"
  echo "base: $BASE"
  echo "proof_path: Phase 2 Track B evidence (see Solum docs/H3-WORKED-EVIDENCE.md)"
  echo "honesty: dual-write link_cdr=true is refused by Solum (example compositions are not patient data)"
} >"$OUT/MANIFEST.txt"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 3 "${GET_HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || skip "H3 sidecar not at $BASE (HTTP $code) — run: make up-h3"

probe="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 "${HDR[@]}" -X POST "$BASE/v1/cdr/template" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"]}" || true)"
[[ "$probe" == "200" || "$probe" == "201" || "$probe" == "204" || "$probe" == "409" ]] \
  || skip "no Track B CDR at $BASE (template HTTP $probe) — run: make up-h3 with ../Solum"

gcode="$(curl_json "$OUT/consent-grant.json" POST "$BASE/v1/consent/grant" "${HDR[@]}" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:consent:grant\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"scope\":[\"patient_summary\"]}")"
[[ "$gcode" == "200" || "$gcode" == "201" ]] \
  || fail "consent grant expected 200/201 got $gcode: $(cat "$OUT/consent-grant.json")"
ok "consent grant for CDR/FHIR"

curl -sS --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/cdr/template" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"]}" >"$OUT/template.json" || fail "template upload"

ehr_code="$(curl_json "$OUT/ehr.json" POST "$BASE/v1/cdr/ehr" "${HDR[@]}" --max-time 60 \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\"}")"
[[ "$ehr_code" == "200" || "$ehr_code" == "201" ]] || fail "ehr create HTTP $ehr_code: $(cat "$OUT/ehr.json")"
ehr_id="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('ehr_id') or '')" "$OUT/ehr.json")"
[[ -n "$ehr_id" ]] || fail "ehr create missing ehr_id: $(cat "$OUT/ehr.json")"
ok "ehr $ehr_id"

comp_code="$(curl_json "$OUT/composition.json" POST "$BASE/v1/cdr/ehr/$ehr_id/composition" "${HDR[@]}" --max-time 60 \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"use_example\":true}")"
[[ "$comp_code" == "200" || "$comp_code" == "201" ]] || fail "composition HTTP $comp_code: $(cat "$OUT/composition.json")"
assert_json "$OUT/composition.json" '"composition_uid" in d' || fail "composition commit missing composition_uid"
ok "composition committed (EHRbase example OPT — not clinical data)"

fhir_code="$(curl_json "$OUT/fhir-patient.json" POST "$BASE/v1/fhir/Patient" "${HDR[@]}" --max-time 60 \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"link_cdr\":false,\"resource\":{\"resourceType\":\"Patient\",\"id\":\"$SUBJECT\",\"name\":[{\"family\":\"Demo\"}]}}")"
[[ "$fhir_code" == "200" || "$fhir_code" == "201" ]] || fail "fhir patient HTTP $fhir_code: $(cat "$OUT/fhir-patient.json")"
assert_json "$OUT/fhir-patient.json" 'd.get("id") == "'"$SUBJECT"'" or d.get("resource", {}).get("id") == "'"$SUBJECT"'"' \
  || fail "fhir patient id mismatch"
ok "fhir Patient $SUBJECT (façade, link_cdr=false)"

curl -sS --max-time 30 "${GET_HDR[@]}" \
  "$BASE/v1/cdr/subject-link/$SUBJECT" >"$OUT/subject-link.json" || fail "subject-link request"
python3 - "$OUT/subject-link.json" "$SUBJECT" <<'PY' || fail "subject-link missing id"
import json, sys
d = json.load(open(sys.argv[1]))
blob = json.dumps(d)
if sys.argv[2] not in blob:
    sys.exit(1)
PY
ok "subject-link"

dw_code="$(curl_json "$OUT/dual-write.json" POST "$BASE/v1/migrate/dual-write" "${HDR[@]}" --max-time 60 \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"link_cdr\":false,\"source\":\"demo-smoke\",\"resource\":{\"resourceType\":\"Patient\",\"id\":\"$SUBJECT\",\"name\":[{\"family\":\"Demo\"}]}}")"
[[ "$dw_code" == "201" ]] || fail "dual-write façade expected 201 got $dw_code: $(cat "$OUT/dual-write.json")"
assert_json "$OUT/dual-write.json" 'd.get("dead_lettered") is False' \
  || fail "dual-write façade must not dead-letter"
ok "dual-write façade HTTP $dw_code (link_cdr=false — FHIR store only, not EHRbase)"

refuse_code="$(curl_json "$OUT/dual-write-link-cdr.json" POST "$BASE/v1/migrate/dual-write" "${HDR[@]}" --max-time 60 \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"link_cdr\":true,\"source\":\"demo-smoke\",\"resource\":{\"resourceType\":\"Condition\",\"id\":\"c-$SUBJECT\",\"subject\":{\"reference\":\"Patient/$SUBJECT\"},\"code\":{\"text\":\"smoke\"}}}")"
[[ "$refuse_code" == "202" ]] || fail "link_cdr=true expected 202 dead-letter got $refuse_code: $(cat "$OUT/dual-write-link-cdr.json")"
assert_json "$OUT/dual-write-link-cdr.json" 'd.get("dead_lettered") is True' \
  || fail "link_cdr=true must dead-letter (Solum refuses example compositions as patient data)"
ok "dual-write link_cdr=true dead-lettered (refused example CDR)"

aql_code="$(curl_json "$OUT/aql.json" POST "$BASE/v1/cdr/aql" "${HDR[@]}" --max-time 60 \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:read\"],\"subject\":\"$SUBJECT\",\"purpose\":\"$PURPOSE\",\"q\":\"SELECT c/uid/value FROM EHR e CONTAINS COMPOSITION c WHERE '$SUBJECT'='$SUBJECT'\"}")"
[[ "$aql_code" == "200" ]] || fail "aql expected 200 got $aql_code: $(cat "$OUT/aql.json")"
ok "aql"

echo "PASS h3" | tee "$OUT/result.txt"
exit 0

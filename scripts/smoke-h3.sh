#!/usr/bin/env bash
# H3 Track B smoke against sidecar-h3 (:8787) + EHRbase.
# Soft-skip (exit 0) when stack is down unless SOLUM_DEMO_H3_REQUIRE=1.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${SOLUM_H3_BASE_URL:-http://127.0.0.1:8787}"
TOKEN="${SOLUM_SIDECAR_TOKEN:-solum-demo-local-token-not-for-production}"
HDR=(-H "X-Solum-Sidecar-Token: $TOKEN" -H "Content-Type: application/json")
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-h3}"
REQUIRE="${SOLUM_DEMO_H3_REQUIRE:-0}"
ACTOR='practitioner/h3'
mkdir -p "$OUT"
{
  echo "Solum-Demo smoke-h3"
  echo "utc: $(date -u +%Y%m%dT%H%M%SZ)"
  echo "base: $BASE"
  echo "proof_path: Phase 2 Track B evidence (see Solum docs/H3-WORKED-EVIDENCE.md)"
} >"$OUT/MANIFEST.txt"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

code="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 3 "${HDR[@]}" "$BASE/v1/audit/export" || true)"
[[ "$code" == "200" ]] || skip "H3 sidecar not at $BASE (HTTP $code) — run: make up-h3"

# Probe CDR route exists (Stage-1 pin has no /v1/cdr)
probe="$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 "${HDR[@]}" -X POST "$BASE/v1/cdr/template" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"]}" || true)"
[[ "$probe" == "200" || "$probe" == "201" || "$probe" == "204" || "$probe" == "409" ]] \
  || skip "no Track B CDR at $BASE (template HTTP $probe) — run: make up-h3 with ../Solum"

# Template
curl -sS --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/cdr/template" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"]}" >"$OUT/template.json" || fail "template upload"

# EHR + composition
ehr="$(curl -sS --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/cdr/ehr" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"]}")"
echo "$ehr" >"$OUT/ehr.json"
ehr_id="$(echo "$ehr" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ehr_id') or '')" 2>/dev/null || true)"
[[ -n "$ehr_id" ]] || fail "ehr create: $ehr"
ok "ehr $ehr_id"

comp="$(curl -sS --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/cdr/ehr/$ehr_id/composition" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"use_example\":true}")"
echo "$comp" >"$OUT/composition.json"
echo "$comp" | grep -q composition_uid || fail "composition commit: $comp"
ok "composition committed"

# FHIR Patient + auto subject-link
pid="demo-h3-$(date -u +%Y%m%d%H%M%S)"
fhir="$(curl -sS --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/fhir/Patient" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"link_cdr\":true,\"resource\":{\"resourceType\":\"Patient\",\"id\":\"$pid\",\"name\":[{\"family\":\"Demo\"}]}}")"
echo "$fhir" >"$OUT/fhir-patient.json"
echo "$fhir" | grep -q "\"id\"" || fail "fhir patient: $fhir"
ok "fhir Patient $pid"

link="$(curl -sS --max-time 30 "${HDR[@]}" \
  "$BASE/v1/cdr/subject-link/$pid?actor=$ACTOR&capability=solum:cdr:read")"
echo "$link" >"$OUT/subject-link.json"
echo "$link" | grep -q "$pid" || fail "subject-link: $link"
ok "subject-link"

# Dual-write (no CDR link to keep smoke fast if EHRbase slow — still exercises route)
dw="$(curl -sS -w "\n%{http_code}" --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/migrate/dual-write" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:write\"],\"link_cdr\":false,\"source\":\"demo-smoke\",\"resource\":{\"resourceType\":\"Condition\",\"id\":\"c-$pid\",\"code\":{\"text\":\"smoke\"}}}")"
dwbody="$(echo "$dw" | sed '$d')"
dwcode="$(echo "$dw" | tail -n1)"
echo "$dwbody" >"$OUT/dual-write.json"
[[ "$dwcode" == "201" || "$dwcode" == "202" ]] || fail "dual-write expected 201/202 got $dwcode: $dwbody"
ok "dual-write HTTP $dwcode"

# AQL allowlist
aql="$(curl -sS -w "\n%{http_code}" --max-time 60 "${HDR[@]}" -X POST "$BASE/v1/cdr/aql" \
  -d "{\"actor\":\"$ACTOR\",\"capability\":[\"solum:cdr:read\"],\"q\":\"SELECT c/uid/value FROM EHR e CONTAINS COMPOSITION c\"}")"
abody="$(echo "$aql" | sed '$d')"
acode="$(echo "$aql" | tail -n1)"
echo "$abody" >"$OUT/aql.json"
[[ "$acode" == "200" ]] || fail "aql expected 200 got $acode: $abody"
ok "aql"

echo "PASS h3" | tee "$OUT/result.txt"
exit 0

#!/usr/bin/env bash
# Structural check of `solum fhir export-ips` output — does NOT re-export via
# solum-example-fhir-ips-export. Optional HL7 JAR runs against the same file.
# Soft-skip if ../Solum missing unless SOLUM_DEMO_FHIR_REQUIRE=1.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOLUM_ROOT="${SOLUM_ROOT:-$ROOT/../Solum}"
OUT="${SOLUM_DEMO_SMOKE_OUT:-$ROOT/artifacts/smoke-fhir-ips}"
REQUIRE="${SOLUM_DEMO_FHIR_REQUIRE:-0}"
mkdir -p "$OUT"

skip() {
  echo "SKIP: $*" | tee "$OUT/result.txt"
  [[ "$REQUIRE" == "1" ]] && exit 1
  exit 0
}
fail() { echo "FAIL: $*" | tee "$OUT/result.txt"; exit 1; }
ok() { echo "OK: $*" | tee -a "$OUT/result.txt"; }

[[ -d "$SOLUM_ROOT/crates/fhir" ]] || skip "Solum checkout not at $SOLUM_ROOT"
SOLUM_ROOT="$(cd "$SOLUM_ROOT" && pwd)"

BUNDLE="$OUT/patient-summary-bundle.json"
(cd "$SOLUM_ROOT" && cargo run -q -p solum-core -- fhir export-ips --out "$BUNDLE") \
  >"$OUT/export-ips.log" 2>&1 \
  || fail "solum fhir export-ips failed — see $OUT/export-ips.log"
ok "solum fhir export-ips wrote bundle"

python3 - "$BUNDLE" "$OUT/structural-check.txt" <<'PY' || fail "structural FHIR checks failed — see $OUT/structural-check.txt"
import json, sys
bundle_path, out_path = sys.argv[1], sys.argv[2]
b = json.load(open(bundle_path, encoding="utf-8"))
checks = []

def ok(name, cond, detail=""):
    checks.append((name, bool(cond), detail))

ok("resourceType=Bundle", b.get("resourceType") == "Bundle")
ok("type=document", b.get("type") == "document")
ok("bdl-9 identifier.system", bool((b.get("identifier") or {}).get("system")))
ok("bdl-9 identifier.value", bool((b.get("identifier") or {}).get("value")))
ok("bdl-10 timestamp", bool(b.get("timestamp")))
entries = b.get("entry") or []
ok("entry non-empty", len(entries) >= 2, f"n={len(entries)}")
comp = (entries[0].get("resource") if entries else {}) or {}
ok("Composition first", comp.get("resourceType") == "Composition")
ok("Composition.type LOINC 60591-5",
   ((comp.get("type") or {}).get("coding") or [{}])[0].get("code") == "60591-5")
ok("Composition.author present", bool(comp.get("author")))
ok("Composition.author.reference", bool((comp.get("author") or [{}])[0].get("reference")))
types = [((e.get("resource") or {}).get("resourceType")) for e in entries]
ok("Patient entry", "Patient" in types)
ok("Organization author entry", "Organization" in types)
ok("AllergyIntolerance entry", "AllergyIntolerance" in types)
ok("MedicationStatement entry", "MedicationStatement" in types)
ok("Condition entry", "Condition" in types)

lines, failed = [], False
for name, passed, detail in checks:
    status = "PASS" if passed else "FAIL"
    if not passed:
        failed = True
    lines.append(f"{status}\t{name}" + (f"\t{detail}" if detail else ""))
open(out_path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("\n".join(lines))
sys.exit(1 if failed else 0)
PY
ok "structural checks of CLI bundle (not the example crate)"

JAR="${FHIR_VALIDATOR_JAR:-}"
if [[ -n "$JAR" && -f "$JAR" ]]; then
  set +e
  java -jar "$JAR" "$BUNDLE" -version 4.0.1 -ig "${FHIR_IPS_IG:-hl7.fhir.uv.ips#2.0.0}" \
    >"$OUT/validator-log.txt" 2>&1
  rc=$?
  set -e
  echo "HL7 validator exit $rc — see $OUT/validator-log.txt" | tee -a "$OUT/validate.log"
else
  echo "SKIP: HL7 Validator JAR not configured (set FHIR_VALIDATOR_JAR)" | tee "$OUT/validator-log.txt"
fi

echo "PASS fhir-ips" | tee "$OUT/result.txt"
exit 0

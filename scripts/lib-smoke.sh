# Shared helpers for Solum-Demo smoke scripts. Sourced, not executed.
# Requires: fail() and ok() defined by the caller.

# Skip-as-fail by default (suite 2026.08-draft). Set SOLUM_DEMO_ALLOW_SKIP=1
# for a laptop without sibling/H3. An explicit SOLUM_DEMO_*_REQUIRE=0|1 wins.
solum_demo_require() {
  local explicit="${1-}"
  if [[ -n "${explicit}" ]]; then
    printf '%s\n' "${explicit}"
    return 0
  fi
  if [[ "${SOLUM_DEMO_ALLOW_SKIP:-0}" == "1" ]]; then
    printf '0\n'
  else
    printf '1\n'
  fi
}

load_sidecar_token() {
  local default='solum-demo-local-token-not-for-production'
  local token="${SOLUM_SIDECAR_TOKEN:-}"
  if [ -z "$token" ] && [ -f "${ROOT}/.env" ]; then
    token="$(sed -n 's/^SOLUM_SIDECAR_TOKEN=//p' "${ROOT}/.env" | tail -1)"
  fi
  if [ -z "$token" ] || [ "$token" = "$default" ]; then
    echo "SOLUM_SIDECAR_TOKEN missing or is the retired default. Run make up." >&2
    exit 1
  fi
  printf '%s' "$token"
}

json_get() {
  # json_get FIELD [default]  — reads JSON on stdin, prints field or default.
  local field="$1"
  local default="${2-}"
  python3 -c '
import json, sys
field, default = sys.argv[1], sys.argv[2]
raw = sys.stdin.read()
try:
    data = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError as e:
    print(f"INVALID_JSON:{e}", file=sys.stderr)
    sys.exit(2)
val = data.get(field, default)
if val is None:
    print("")
elif isinstance(val, (dict, list)):
    print(json.dumps(val, separators=(",", ":")))
else:
    print(val)
' "$field" "$default"
}

assert_json() {
  # assert_json FILE python-expr-using-d
  local file="$1"
  local expr="$2"
  python3 -c '
import json, sys
path, expr = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as fh:
    d = json.load(fh)
ok = eval(expr, {"d": d, "json": json})  # noqa: S307 — smoke-local expr
if not ok:
    print(f"assertion failed: {expr}\nbody={json.dumps(d, indent=2)[:2000]}", file=sys.stderr)
    sys.exit(1)
' "$file" "$expr"
}

# Sidecar GET identity (dev-local client-asserted caps). Token is also injected
# by nginx; sending it here keeps scripts working against sidecar:8787 directly.
audit_get_headers() {
  local token="$1"
  local actor="${2:-practitioner/amina}"
  printf '%s' \
    "-H" "X-Solum-Sidecar-Token: ${token}" \
    "-H" "X-Solum-Actor: ${actor}" \
    "-H" "X-Solum-Capability: solum:audit:export,solum:audit:verify,solum:consent:read" \
    "-H" "Content-Type: application/json"
}

curl_json() {
  # curl_json OUTFILE METHOD URL extra curl args...
  # Writes body to OUTFILE, prints HTTP code on stdout.
  local out="$1"
  local method="$2"
  local url="$3"
  shift 3
  local tmp
  tmp="$(mktemp)"
  local code
  code="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$@" "$url" || true)"
  mv "$tmp" "$out"
  printf '%s' "$code"
}

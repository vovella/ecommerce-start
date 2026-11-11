#!/usr/bin/env bash
# Module 01: smoke test for running services.
# Usage: ./test_services.sh [BASE_URL]   (default http://localhost:8501)
# Exit codes: 0 = all checks passed, 1 = at least one check failed, 2 = missing dependency.
set -u

BASE_URL="${1:-${BASE_URL:-http://localhost:8501}}"
COMPOSE_SERVICE="chat-agent"
FAILED=0

command -v curl >/dev/null || { echo "curl is required"; exit 2; }

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAILED=$((FAILED + 1)); }

# check_http NAME PATH EXPECTED_CODE [EXPECTED_BODY_SUBSTRING]
check_http() {
  local name="$1" path="$2" want_code="$3" want_body="${4:-}"
  local body code
  body="$(curl -s --max-time 10 -w '\n%{http_code}' "$BASE_URL$path")" || { fail "$name: no response from $BASE_URL$path"; return; }
  code="${body##*$'\n'}"
  body="${body%$'\n'*}"
  if [ "$code" != "$want_code" ]; then
    fail "$name: HTTP $code, expected $want_code"
  elif [ -n "$want_body" ] && ! grep -q -- "$want_body" <<<"$body"; then
    fail "$name: HTTP $code but body does not contain '$want_body'"
  else
    pass "$name (HTTP $code)"
  fi
}

echo "Testing $BASE_URL"

echo "[1] Container"
if command -v docker >/dev/null && docker compose ps --status running --services 2>/dev/null | grep -qx "$COMPOSE_SERVICE"; then
  pass "docker compose service '$COMPOSE_SERVICE' is running"
elif command -v docker >/dev/null && [ -f docker-compose.yml ]; then
  fail "docker compose service '$COMPOSE_SERVICE' is not running"
else
  echo "  SKIP  not in the project root or docker unavailable (HTTP checks only)"
fi

echo "[2] HTTP endpoints"
check_http "UI index"         "/"                    200 "<title>Streamlit</title>"
check_http "Health"           "/_stcore/health"      200 "ok"
check_http "Host config"      "/_stcore/host-config" 200 "allowedOrigins"

echo "[3] Data visible to the service"
if command -v docker >/dev/null && [ -f docker-compose.yml ]; then
  rows="$(docker compose exec -T "$COMPOSE_SERVICE" python -c "import pandas as pd; print(len(pd.read_csv('data/products.csv')))" 2>/dev/null)"
  if [ "${rows:-0}" -gt 0 ] 2>/dev/null; then pass "data/products.csv loaded: $rows products"; else fail "data/products.csv is missing or empty (run the data generator)"; fi
else
  echo "  SKIP  docker unavailable"
fi

echo
if [ "$FAILED" -eq 0 ]; then echo "All checks passed"; exit 0; fi
echo "$FAILED check(s) failed"; exit 1

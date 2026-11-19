#!/usr/bin/env bash
set -Eeuo pipefail

base_url=${BASE_URL:-http://127.0.0.1:${HOST_PORT:-8080}}
"$(dirname "$0")/health-check.sh" "$base_url/health/ready"
curl -fsS "$base_url/version" | grep -q version
payload='{"hostname":"smoke-01.local","ip_address":"10.20.30.40","environment":"test","description":"smoke test"}'
status=$(curl -sS -o /tmp/portal-smoke.json -w '%{http_code}' -H 'Content-Type: application/json' -d "$payload" "$base_url/api/assets")
[[ $status == 201 || $status == 409 ]] || { echo "Asset smoke request failed: HTTP $status" >&2; exit 1; }
curl -fsS "$base_url/api/assets" | grep -q smoke-01.local
echo "API smoke test passed."

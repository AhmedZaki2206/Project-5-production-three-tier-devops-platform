#!/usr/bin/env bash
set -Eeuo pipefail

url=${1:-http://127.0.0.1:${HOST_PORT:-8080}/health/ready}
attempts=${HEALTH_ATTEMPTS:-30}

for ((attempt = 1; attempt <= attempts; attempt++)); do
  if response=$(curl -fsS --max-time 3 "$url") && grep -q '"ready"' <<<"$response"; then
    echo "Readiness check passed: $url"
    exit 0
  fi
  echo "Waiting for readiness ($attempt/$attempts)..."
  sleep 2
done

echo "Readiness check failed: $url" >&2
exit 1

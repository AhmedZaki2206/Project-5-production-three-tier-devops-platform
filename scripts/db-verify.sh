#!/usr/bin/env bash
set -Eeuo pipefail

result=$(docker compose -p three-tier-devops-platform exec -T db sh -c \
  'psql -Atqc "SELECT to_regclass('"'"'public.assets'"'"') IS NOT NULL" -U "$POSTGRES_USER" -d "$POSTGRES_DB"')
[[ $result == t ]] || { echo "Database verification failed: assets table missing" >&2; exit 1; }
count=$(docker compose -p three-tier-devops-platform exec -T db sh -c \
  'psql -Atqc "SELECT count(*) FROM assets" -U "$POSTGRES_USER" -d "$POSTGRES_DB"')
echo "Database verified. assets rows=$count"

#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
backup_dir="$project_root/backups"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_file="$backup_dir/portal-$timestamp.sql.gz"
mkdir -p "$backup_dir"

docker compose -p three-tier-devops-platform exec -T db sh -c \
  'pg_dump --clean --if-exists --no-owner --no-privileges -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip -9 >"$backup_file"

gzip -t "$backup_file"
[[ -s $backup_file ]] || { echo "Backup is empty" >&2; exit 1; }
echo "Backup created and gzip-validated: $backup_file"
echo "Run scripts/db-restore.sh with this file to verify recoverability."

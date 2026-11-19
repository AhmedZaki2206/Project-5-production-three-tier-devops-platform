#!/usr/bin/env bash
set -Eeuo pipefail

usage() { echo "Usage: $0 BACKUP.sql.gz [--yes]"; }
backup_input=${1:-}
confirmation=${2:-}
[[ -n $backup_input ]] || { usage; exit 64; }
[[ -f $backup_input ]] || { echo "Backup file not found: $backup_input" >&2; exit 66; }
[[ $backup_input == *.sql.gz ]] || { echo "Expected a .sql.gz backup" >&2; exit 65; }
gzip -t "$backup_input"

echo "WARNING: this restore overwrites objects in the project database."
if [[ $confirmation != --yes ]]; then
  read -r -p "Type RESTORE to continue: " answer
  [[ $answer == RESTORE ]] || { echo "Restore cancelled"; exit 1; }
fi

gzip -dc "$backup_input" | docker compose -p three-tier-devops-platform exec -T db sh -c \
  'psql --set ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
"$(dirname "$0")/db-verify.sh"
echo "Restore completed and database verification passed."

#!/usr/bin/env bash
set -Eeuo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state_dir="$project_root/.lab-state"
catalog="$project_root/incidents/catalog.tsv"
mkdir -p "$state_dir"

valid_id() { grep -q "^$1[[:space:]]" "$catalog"; }
active_id() {
  if [[ -f $state_dir/active ]]; then
    cat "$state_dir/active"
  fi
}
baseline() { docker compose -p three-tier-devops-platform up -d; }
reset_lab() {
  docker compose -p three-tier-devops-platform down --remove-orphans >/dev/null 2>&1 || true
  if [[ -f $state_dir/test_api.py ]]; then
    cp "$state_dir/test_api.py" "$project_root/tests/test_api.py"
  fi
  rm -f "$state_dir/active" "$state_dir/test_api.py" "$state_dir/corrupt.sql.gz"
  baseline
}

command=${1:-}
case "$command" in
  list) column -t -s $'\t' "$catalog" 2>/dev/null || cat "$catalog" ;;
  status) echo "Active incident: $(active_id)"; docker compose -p three-tier-devops-platform ps ;;
  hint)
    id=${2:-}; valid_id "$id" || exit 64
    grep "^$id|" "$project_root/incidents/hints.txt" | cut -d'|' -f2-
    ;;
  start)
    id=${2:-}; valid_id "$id" || { echo "Invalid incident ID" >&2; exit 64; }
    current=$(active_id); [[ -z $current ]] || { echo "Reset incident $current first" >&2; exit 65; }
    baseline
    case "$id" in
      01) docker compose -p three-tier-devops-platform -f docker-compose.yml -f faults/01-bad-gateway.yaml up -d --force-recreate proxy ;;
      02) docker compose -p three-tier-devops-platform -f docker-compose.yml -f faults/02-crash-loop.yaml up -d --force-recreate app proxy ;;
      03) docker compose -p three-tier-devops-platform stop db ;;
      04) docker compose -p three-tier-devops-platform -f docker-compose.yml -f faults/04-bad-credentials.yaml up -d --force-recreate app proxy ;;
      05) docker compose -p three-tier-devops-platform -f docker-compose.yml -f faults/05-network-isolation.yaml up -d --force-recreate app proxy ;;
      06) docker compose -p three-tier-devops-platform down; docker compose -p three-tier-devops-platform -f docker-compose.yml -f faults/06-volume.yaml up -d db ;;
      07) docker compose -p three-tier-devops-platform -f docker-compose.yml -f faults/07-readiness.yaml up -d --force-recreate app proxy ;;
      08) cp tests/test_api.py "$state_dir/test_api.py"; printf '\n\ndef test_intentional_ci_failure():\n    assert False\n' >>tests/test_api.py ;;
      09) echo "Try: docker pull ghcr.io/example/three-tier-portal:does-not-exist" ;;
      10) printf 'not a valid gzip backup\n' >"$state_dir/corrupt.sql.gz" ;;
    esac
    printf '%s\n' "$id" >"$state_dir/active"
    echo "Incident $id started. Investigate before reading the solution."
    ;;
  reset|reset-all) reset_lab; echo "Lab reset to baseline." ;;
  *) echo "Usage: ./lab.sh {list|start ID|status|hint ID|reset ID|reset-all}"; exit 64 ;;
esac

#!/usr/bin/env bash
set -Eeuo pipefail

image=${1:-three-tier-portal:local}
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
state_dir="$project_root/.deployment"
current_file="$state_dir/current-image"
previous_file="$state_dir/previous-image"
mkdir -p "$state_dir"

docker compose -p three-tier-devops-platform config --quiet
if [[ -f $current_file ]] && [[ $(<"$current_file") != "$image" ]]; then
  cp "$current_file" "$previous_file"
fi

if [[ $image == three-tier-portal:local ]]; then
  docker compose -p three-tier-devops-platform build app migrate
else
  docker pull "$image"
fi

APP_IMAGE="$image" docker compose -p three-tier-devops-platform up -d --remove-orphans
if ! "$project_root/scripts/health-check.sh"; then
  echo "Deployment failed readiness; inspect docker compose logs." >&2
  exit 1
fi
printf '%s\n' "$image" >"$current_file"
echo "Deployment healthy: $image"

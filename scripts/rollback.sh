#!/usr/bin/env bash
set -Eeuo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
state_dir="$project_root/.deployment"
previous_file="$state_dir/previous-image"
[[ -s $previous_file ]] || { echo "No recorded previous image tag" >&2; exit 66; }
previous_image=$(<"$previous_file")

echo "Rolling application image back to: $previous_image"
APP_IMAGE="$previous_image" docker compose -p three-tier-devops-platform up -d app proxy
"$project_root/scripts/health-check.sh"
printf '%s\n' "$previous_image" >"$state_dir/current-image"
echo "Application rollback passed readiness. Database migrations were not reversed."

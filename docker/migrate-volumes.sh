#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TARGET_ROOT="${SCRIPT_DIR}/volumes"
TARGET_ROOT="${1:-$DEFAULT_TARGET_ROOT}"

declare -A VOLUME_MAP=(
  [jenkins_home]=jenkins
  [minio_data]=minio
  [postgres_data]=postgres
  [registry_data]=registry
)

mkdir -p "$TARGET_ROOT"

for volume in "${!VOLUME_MAP[@]}"; do
  if docker volume inspect "$volume" >/dev/null 2>&1; then
    dest_dir="${TARGET_ROOT}/${VOLUME_MAP[$volume]}"
    mkdir -p "$dest_dir"
    echo "Copying volume '$volume' to '$dest_dir'..."
    docker run --rm \
      -v "${volume}:/source" \
      -v "${dest_dir}:/dest" \
      alpine:3.19 \
      sh -c "cp -a /source/. /dest/"
  else
    echo "Skipping volume '$volume' (not found)."
  fi
done

echo "Migration complete. Update docker-compose.yml to use bind mounts pointing to '$TARGET_ROOT'."

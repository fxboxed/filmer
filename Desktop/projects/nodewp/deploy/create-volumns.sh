#!/usr/bin/env bash
set -euo pipefail

# Create named volumes if missing. Safe to re-run.

volumes=(nwh-db nwh-wp nwh-caddy-data nwh-caddy-config)

for v in "${volumes[@]}"; do
  if ! podman volume inspect "$v" >/dev/null 2>&1; then
    echo "Creating volume: $v"
    podman volume create "$v" >/dev/null
  else
    echo "Volume exists: $v"
  fi
done

echo "All volumes ready."

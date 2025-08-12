#!/usr/bin/env bash
# deploy/deploy.sh
# Automated deploy with:
# - .env safeguard (auto-copies .env.example on first run)
# - Auto-free ports: $PORT (Node, default 3000), 8080 (WP), 80/443 (Caddy)
# - Logs process names/commands before killing
# - AUTO-DETECTS WP_BASE_URL when set to "auto" or unset:
#     * Pod mode (WP+Node in same pod): http://127.0.0.1:8080
#     * Local non-pod dev:               http://localhost:8080

set -euo pipefail

# === Locate script dir ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Safeguard: Ensure .env exists (copy from .env.example on first run) ===
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo ">>> No .env found in $SCRIPT_DIR"
  if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
    echo ">>> Copying .env.example → .env"
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    echo ">>> Created $SCRIPT_DIR/.env — please edit real values, then re-run."
    exit 1
  else
    echo "!!! ERROR: No .env or .env.example found in $SCRIPT_DIR"
    exit 1
  fi
fi

# === Load env file ===
set -a
source "$SCRIPT_DIR/.env"
set +a

# ===== Helpers =====
free_host_port() {
  local port="$1"
  echo ">>> Checking host for listeners on :$port"
  local pids
  pids=$(sudo lsof -nP -t -i :"$port" -sTCP:LISTEN 2>/dev/null || true)

  if [[ -z "${pids}" ]]; then
    echo "    No host processes bound to :$port"
    return 0
  fi

  echo "    Found host listeners on :$port:"
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    local name cmd
    name=$(ps -p "$pid" -o comm= 2>/dev/null || true)
    cmd=$(ps -p "$pid" -o args= 2>/dev/null || true)
    echo "      - PID $pid  NAME: ${name:-unknown}"
    echo "        CMD: ${cmd:-<unavailable>}"
  done <<< "$pids"

  echo "    Sending SIGTERM..."
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    sudo kill "$pid" 2>/dev/null || true
  done <<< "$pids"
  sleep 1

  local still
  still=$(sudo lsof -nP -t -i :"$port" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "${still}" ]]; then
    echo "    Still alive after SIGTERM:"
    while read -r pid; do
      [[ -z "$pid" ]] && continue
      local name cmd
      name=$(ps -p "$pid" -o comm= 2>/dev/null || true)
      cmd=$(ps -p "$pid" -o args= 2>/dev/null || true)
      echo "      - PID $pid  NAME: ${name:-unknown}"
      echo "        CMD: ${cmd:-<unavailable>}"
    done <<< "$still"
    echo "    Escalating to SIGKILL..."
    while read -r pid; do
      [[ -z "$pid" ]] && continue
      sudo kill -9 "$pid" 2>/dev/null || true
    done <<< "$still"
    sleep 0.5
  fi

  if sudo lsof -nP -i :"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "!!  Could not free host port :$port (still in use)."
    exit 1
  fi

  echo "    Port :$port is free."
}

stop_podman_containers_on_port() {
  local port="$1"
  echo ">>> Checking Podman containers on :$port"
  local matches
  matches=$(podman ps --format '{{.ID}} {{.Names}} {{.Ports}}' | grep -E "(:$port->|:$port/)" || true)

  if [[ -z "${matches}" ]]; then
    echo "    No containers exposing :$port"
    return 0
  fi

  echo "    Containers exposing :$port:"
  while read -r line; do
    [[ -z "$line" ]] && continue
    local cid cname ports image
    cid=$(awk '{print $1}' <<<"$line")
    cname=$(awk '{print $2}' <<<"$line")
    ports=$(cut -d' ' -f3- <<<"$line")
    image=$(podman inspect --format '{{.ImageName}}' "$cid" 2>/dev/null || echo "unknown-image")
    echo "      - $cname ($cid)"
    echo "        Image: $image"
    echo "        Ports: $ports"
  done <<< "$matches"

  echo "    Stopping & removing containers on :$port..."
  while read -r line; do
    [[ -z "$line" ]] && continue
    local cid
    cid=$(awk '{print $1}' <<<"$line")
    podman stop "$cid" >/dev/null || true
    podman rm "$cid" >/dev/null || true
  done <<< "$matches"
}

recreate() {
  local name="$1"; shift
  if podman container exists "$name"; then
    echo ">>> Stopping existing container: $name"
    podman stop "$name" >/dev/null || true
    echo ">>> Removing existing container: $name"
    podman rm "$name" >/dev/null || true
  fi
  echo ">>> Creating container: $name"
  podman run "$@"
}

# ===== AUTO-DETECT WP_BASE_URL (runtime override for Node) =====
# If WP_BASE_URL is unset or set to "auto", choose the best value.
# - If a pod named 'nwh' exists (or we’re about to use it), prefer in-pod loopback.
# - Else assume local host dev.
if [[ -z "${WP_BASE_URL:-}" || "${WP_BASE_URL,,}" == "auto" ]]; then
  if podman pod exists nwh; then
    WP_BASE_URL_USED="http://127.0.0.1:8080"
  else
    WP_BASE_URL_USED="http://localhost:8080"
  fi
else
  WP_BASE_URL_USED="$WP_BASE_URL"
fi
echo ">>> Using WP_BASE_URL at runtime: $WP_BASE_URL_USED"

# ===== Pre-flight: free ports =====
PORT="${PORT:-3000}"
ALL_PORTS=("$PORT" 8080 80 443)

echo "=== Freeing all needed ports: ${ALL_PORTS[*]} ==="
for p in "${ALL_PORTS[@]}"; do
  stop_podman_containers_on_port "$p"
  free_host_port "$p"
done
echo "=== Ports are clear. ==="

# ===== Pod =====
if ! podman pod exists nwh; then
  echo ">>> Creating pod 'nwh' (publishing 80/443 + $PORT + 8080)"
  podman pod create --name nwh \
    --publish 80:80 \
    --publish 443:443 \
    --publish "$PORT:$PORT" \
    --publish 8080:8080 >/dev/null
else
  echo ">>> Pod 'nwh' already exists."
fi

# ===== Volumes =====
"$SCRIPT_DIR/create-volumes.sh"

# ===== Database =====
recreate nwh-db -d --name nwh-db --pod nwh \
  -e MARIADB_DATABASE="$MARIADB_DATABASE" \
  -e MARIADB_USER="$MARIADB_USER" \
  -e MARIADB_PASSWORD="$MARIADB_PASSWORD" \
  -e MARIADB_ROOT_PASSWORD="$MARIADB_ROOT_PASSWORD" \
  -v nwh-db:/var/lib/mysql \
  docker.io/library/mariadb:11

# ===== WordPress =====
echo "=== Final check: keep :8080 free for WordPress ==="
stop_podman_containers_on_port 8080
free_host_port 8080
recreate nwh-wp -d --name nwh-wp --pod nwh \
  -e WORDPRESS_DB_HOST=127.0.0.1:3306 \
  -e WORDPRESS_DB_USER="$MARIADB_USER" \
  -e WORDPRESS_DB_PASSWORD="$MARIADB_PASSWORD" \
  -e WORDPRESS_DB_NAME="$MARIADB_DATABASE" \
  -e APACHE_LISTEN_PORT=8080 \
  -v nwh-wp:/var/www/html \
  docker.io/library/wordpress:6-php8.2-apache

# ===== Caddy =====
for p in 80 443; do
  echo "=== Final check: keep :$p free for Caddy ==="
  stop_podman_containers_on_port "$p"
  free_host_port "$p"
done
if ! podman container exists nwh-caddy; then
  echo ">>> Seeding Caddyfile into config volume (first run only)"
  TMPDIR=$(mktemp -d)
  cp "$SCRIPT_DIR/Caddyfile" "$TMPDIR/Caddyfile"
  podman run --rm -v nwh-caddy-config:/etc/caddy -v "$TMPDIR:/src:ro" alpine sh -c '
    if [ ! -f /etc/caddy/Caddyfile ]; then cp /src/Caddyfile /etc/caddy/Caddyfile; fi
  '
  rm -rf "$TMPDIR"
fi
recreate nwh-caddy -d --name nwh-caddy --pod nwh \
  -v nwh-caddy-config:/etc/caddy \
  -v nwh-caddy-data:/data \
  -e ACME_AGREE=true \
  -e ACME_EMAIL="${ACME_EMAIL:-}" \
  docker.io/library/caddy:2 caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

# ===== Node app =====
echo "=== Final check: keep :$PORT free for Node ==="
stop_podman_containers_on_port "$PORT"
free_host_port "$PORT"
recreate nwh-node -d --name nwh-node --pod nwh \
  --env-file "$SCRIPT_DIR/.env" \
  -e WP_BASE_URL="$WP_BASE_URL_USED" \
  localhost/node-pug-stylus-app:latest

echo
echo "Deployment done."
echo "Node will use WP_BASE_URL: $WP_BASE_URL_USED"
echo "Local test:  http://localhost:${PORT}  (Node),  http://localhost:8080  (WordPress)"





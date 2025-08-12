#!/usr/bin/env bash
# Dump local WP DB → gzip → scp to server → (optional) import & fix URLs on server.
# Uses DB creds from deploy/.env and DB container nwh-db (or auto-detected).
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# EDIT THESE TWO LINES (or pass via CLI flags below)
SERVER="root@91.98.77.223"            # user@host (or user@ip)
NEW_DOMAIN="https://mylivesite.com"   # only used if --import is provided
# ─────────────────────────────────────────────────────────────

# CLI flags (optional):
#   --server user@host       override SERVER
#   --domain https://domain  override NEW_DOMAIN
#   --import                 also import on server & set siteurl/home
#   --db nwh-db              override local DB container name
#   --name outname.sql.gz    custom local/remote file name
DO_IMPORT="no"
LOCAL_DB_CONT=""
OUT_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server) SERVER="$2"; shift 2 ;;
    --domain) NEW_DOMAIN="$2"; shift 2 ;;
    --import) DO_IMPORT="yes"; shift ;;
    --db)     LOCAL_DB_CONT="$2"; shift 2 ;;
    --name)   OUT_NAME="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--server user@host] [--domain https://domain] [--import] [--db container] [--name file.sql.gz]"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Locate script dir & load env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo "ERROR: $SCRIPT_DIR/.env not found. Create it (or copy from .env.example) and fill DB vars."
  exit 1
fi
set -a
source "$SCRIPT_DIR/.env"   # loads MARIADB_* vars
set +a

# Sensible defaults
PORT="${PORT:-3000}"
STAMP="$(date +%Y%m%d-%H%M)"
OUT_NAME="${OUT_NAME:-site-backup-${STAMP}.sql.gz}"
LOCAL_OUT="/tmp/${OUT_NAME}"
REMOTE_OUT="/tmp/${OUT_NAME}"

# Find local DB container if not provided
if [[ -z "${LOCAL_DB_CONT:-}" ]]; then
  # Prefer nwh-db if present; otherwise pick the first container with "db" in the name.
  if podman container exists nwh-db; then
    LOCAL_DB_CONT="nwh-db"
  else
    LOCAL_DB_CONT="$(podman ps --format '{{.Names}}' | grep -iE 'db|mariadb|mysql' | head -n1 || true)"
  fi
fi

if [[ -z "${LOCAL_DB_CONT:-}" ]]; then
  echo "ERROR: Could not auto-detect a DB container. Pass --db <container>."
  exit 1
fi

echo ">>> Using local DB container: ${LOCAL_DB_CONT}"
echo ">>> Output (local): ${LOCAL_OUT}"
echo ">>> Server: ${SERVER}"
if [[ "${DO_IMPORT}" == "yes" ]]; then
  echo ">>> Will import on server and set siteurl/home to: ${NEW_DOMAIN}"
fi
echo

# Sanity: check required envs
: "${MARIADB_USER:?Missing MARIADB_USER in deploy/.env}"
: "${MARIADB_PASSWORD:?Missing MARIADB_PASSWORD in deploy/.env}"
: "${MARIADB_DATABASE:?Missing MARIADB_DATABASE in deploy/.env}"

# 1) Local dump → gzip → /tmp/…
echo "==> Dumping local DB from ${LOCAL_DB_CONT}..."
podman exec -i "${LOCAL_DB_CONT}" sh -lc \
  'mysqldump -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
| gzip > "${LOCAL_OUT}"

ls -lh "${LOCAL_OUT}" || true
echo "OK: Local dump created."

# 2) SCP to server:/tmp
echo "==> Uploading to ${SERVER}:${REMOTE_OUT} ..."
scp "${LOCAL_OUT}" "${SERVER}:${REMOTE_OUT}"
echo "OK: Uploaded."

# 3) Optional: import on server + set URLs
if [[ "${DO_IMPORT}" == "yes" ]]; then
  echo "==> Importing on server into nwh-db and updating URLs..."
  ssh "${SERVER}" bash -lc "
    set -euo pipefail
    # Import dump into the running nwh-db container
    podman exec -i nwh-db sh -lc 'gunzip -c ${REMOTE_OUT} | mysql -u\"\$MARIADB_USER\" -p\"\$MARIADB_PASSWORD\" \"\$MARIADB_DATABASE\"'
    echo 'OK: DB imported.'
    # Update wp_options siteurl/home
    podman exec -i nwh-db sh -lc \"mysql -u\\\"\$MARIADB_USER\\\" -p\\\"\$MARIADB_PASSWORD\\\" \\\"\$MARIADB_DATABASE\\\" -e \\
      \\\"UPDATE wp_options SET option_value='${NEW_DOMAIN}' WHERE option_name IN ('siteurl','home');\\\" \"
    echo 'OK: siteurl/home updated to ${NEW_DOMAIN}.'
  "
  echo "All done: imported and URLs updated."
else
  echo "Skipping server import (run with --import to do it automatically)."
fi

echo
echo "Summary:"
echo "  Local dump:   ${LOCAL_OUT}"
echo "  Remote dump:  ${SERVER}:${REMOTE_OUT}"
if [[ "${DO_IMPORT}" == "yes" ]]; then
  echo "  Server DB:    imported into nwh-db"
  echo "  Site URLs:    set to ${NEW_DOMAIN}"
fi
echo "Done."

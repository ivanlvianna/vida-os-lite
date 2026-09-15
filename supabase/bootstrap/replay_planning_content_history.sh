#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?Set DATABASE_URL for a disposable database already migrated through canonical v0.7}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTSTRAP_GZ="$ROOT_DIR/supabase/bootstrap/PLANNING_CONTENT_CURRENT_BOOTSTRAP_20260914.sql.gz"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required" >&2
  exit 2
fi

if [[ ! -f "$BOOTSTRAP_GZ" ]]; then
  echo "Missing bootstrap artifact: $BOOTSTRAP_GZ" >&2
  exit 3
fi

# Never point DATABASE_URL at official homologation or production.
gzip -dc "$BOOTSTRAP_GZ" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1

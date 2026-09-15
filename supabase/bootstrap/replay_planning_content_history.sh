#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?Set DATABASE_URL for a disposable database already migrated through canonical v0.7}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCHIVE="$ROOT_DIR/supabase/history/archives/PLANNING_CONTENT_EXACT_APPLIED_HISTORY_20260914.tar.gz"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required" >&2
  exit 2
fi

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Missing applied-history archive: $ARCHIVE" >&2
  exit 3
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

tar -xzf "$ARCHIVE" -C "$TMP_DIR"

mapfile -t MIGRATIONS < <(find "$TMP_DIR" -maxdepth 1 -type f -name '2026*.sql' -print | sort)

if [[ "${#MIGRATIONS[@]}" -ne 28 ]]; then
  echo "Expected 28 Planning Content migrations, found ${#MIGRATIONS[@]}" >&2
  exit 4
fi

# Never point DATABASE_URL at official homologation or production.
for migration in "${MIGRATIONS[@]}"; do
  echo "Applying $(basename "$migration")"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$migration"
done

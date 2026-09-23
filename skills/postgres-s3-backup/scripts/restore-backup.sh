#!/usr/bin/env bash
# Restore a dump from S3 into a database of your choosing. Run with credentials that can
# list and read the bucket (an operator, not the server's write-only role).
#
#   restore-backup.sh <bucket> <prefix> <object-key|latest> <target-postgres-url>
#
# The target is a plain postgresql:// URL without the password. Supply the password through
# ~/.pgpass, or a prompt, so it stays out of the process list and shell history:
#
#   read -rs PGPASSWORD && export PGPASSWORD
#   restore-backup.sh <bucket> <prefix> latest postgresql://<user>@localhost:5432/<db>_restore
#
# Restore into a fresh database and inspect
# it before swapping it in; this script refuses to restore into a database that already
# has tables unless FORCE=1 is set.
set -euo pipefail
BUCKET="${1:?bucket}"; PREFIX="${2:?prefix}"; KEY="${3:?object key or latest}"; TARGET="${4:?target postgresql:// url}"
DATABASE_URL="$TARGET"
# Move the password out of the URL into PGPASSWORD: arguments show in `ps` for every user,
# the environment only to root and the owner. Percent-encoding is decoded for libpq.
if [[ $DATABASE_URL =~ ^(postgresql://[^:/@]+):([^@]*)@(.*)$ ]]; then
  pw="${BASH_REMATCH[2]//\\/\\\\}"
  export PGPASSWORD="$(printf '%b' "${pw//%/\\x}")"
  DATABASE_URL="${BASH_REMATCH[1]}@${BASH_REMATCH[3]}"
fi
[ "$DATABASE_URL" = "$TARGET" ] || echo "warning: the password was on this script's command line; use PGPASSWORD or ~/.pgpass next time" >&2
TARGET="$DATABASE_URL"

if [ "$KEY" = latest ]; then
  KEY="$(aws s3 ls "s3://$BUCKET/$PREFIX/" | awk '{print $4}' | sort | tail -1)"
  [ -n "$KEY" ] || { echo "no objects under s3://$BUCKET/$PREFIX/" >&2; exit 1; }
fi
echo "restoring s3://$BUCKET/$PREFIX/$KEY"

TABLES="$(psql "$TARGET" -tAc "select count(*) from pg_tables where schemaname='public'")"
if [ "$TABLES" != 0 ] && [ "${FORCE:-0}" != 1 ]; then
  echo "target already has $TABLES tables; restore into a fresh database or set FORCE=1" >&2
  exit 1
fi

aws s3 cp "s3://$BUCKET/$PREFIX/$KEY" - | gunzip | psql -v ON_ERROR_STOP=1 -q "$TARGET"
echo "restored. tables now: $(psql "$TARGET" -tAc "select count(*) from pg_tables where schemaname='public'")"

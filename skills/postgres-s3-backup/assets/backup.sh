#!/usr/bin/env bash
# Nightly pg_dump to S3. Cron (UTC): 0 3 * * * root /opt/<app>/backup.sh
set -euo pipefail
cd "$(dirname "$0")"
ENV_FILE="<app>.env"

DATABASE_URL="$(grep '^DATABASE_URL=' "$ENV_FILE" | cut -d= -f2- | sed 's|^postgresql+[a-z0-9]*://|postgresql://|')"
# Move the password out of the URL into PGPASSWORD: arguments show in `ps` for every user,
# the environment only to root and the owner. Percent-encoding is decoded for libpq.
if [[ $DATABASE_URL =~ ^(postgresql://[^:/@]+):([^@]*)@(.*)$ ]]; then
  pw="${BASH_REMATCH[2]//\\/\\\\}"
  export PGPASSWORD="$(printf '%b' "${pw//%/\\x}")"
  DATABASE_URL="${BASH_REMATCH[1]}@${BASH_REMATCH[3]}"
fi
BUCKET="$(grep '^BACKUP_BUCKET=' "$ENV_FILE" | cut -d= -f2-)"
: "${BUCKET:?BACKUP_BUCKET is not set in $ENV_FILE}"

pg_dump "$DATABASE_URL" | gzip \
  | aws s3 cp - "s3://$BUCKET/<app>/$(date +%Y%m%d-%H%M%S).sql.gz"

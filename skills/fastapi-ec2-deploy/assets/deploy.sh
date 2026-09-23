#!/usr/bin/env bash
# Runs on the box as root: /opt/<app>/deploy.sh <registry>/<repo>:<tag>
# Logs in to ECR with the instance role, pulls, dumps the database, migrates, restarts
# the backend and waits for it to report healthy. Rollback is the same command with an
# older tag.
set -euo pipefail
cd "$(dirname "$0")"

IMAGE="${1:?usage: deploy.sh <image>}"
REGISTRY="${IMAGE%%/*}"
REGION="$(cut -d. -f4 <<<"$REGISTRY")"
ENV_FILE="<app>.env"
HEALTH_URL="http://127.0.0.1:8000/api/health"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "APP_IMAGE=$IMAGE" > .env
docker compose pull

# pg_dump does not understand the SQLAlchemy driver prefix.
DATABASE_URL="$(grep '^DATABASE_URL=' "$ENV_FILE" | cut -d= -f2- | sed 's|^postgresql+[a-z0-9]*://|postgresql://|')"
# Move the password out of the URL into PGPASSWORD: arguments show in `ps` for every user,
# the environment only to root and the owner. Percent-encoding is decoded for libpq.
if [[ $DATABASE_URL =~ ^(postgresql://[^:/@]+):([^@]*)@(.*)$ ]]; then
  pw="${BASH_REMATCH[2]//\\/\\\\}"
  export PGPASSWORD="$(printf '%b' "${pw//%/\\x}")"
  DATABASE_URL="${BASH_REMATCH[1]}@${BASH_REMATCH[3]}"
fi
mkdir -p backups
pg_dump "$DATABASE_URL" | gzip > "backups/pre-deploy-$(date +%Y%m%d-%H%M%S).sql.gz"
find backups -name 'pre-deploy-*.sql.gz' -mtime +14 -delete

docker compose run --rm backend alembic upgrade head
docker compose up -d

for _ in $(seq 1 30); do
  if curl -fsS "$HEALTH_URL" >/dev/null; then
    docker image prune -f >/dev/null
    echo "deployed $IMAGE"
    exit 0
  fi
  sleep 2
done

echo "backend did not become healthy" >&2
docker compose logs --tail 50 backend >&2
exit 1

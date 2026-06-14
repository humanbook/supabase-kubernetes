#!/bin/bash
set -e

IMAGE="supabase-postgres:18"
CONTAINER="supabase-db"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
PORT="${PORT:-5432}"
VOLUME="${VOLUME:-supabase-pgdata}"

# Build image with extensions
docker build -t "$IMAGE" .

# Remove existing container if any
docker rm -f "$CONTAINER" 2>/dev/null || true

# Start container
docker volume create "$VOLUME" 2>/dev/null || true
docker run -d \
  --name "$CONTAINER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -p "${PORT}:5432" \
  -v "$VOLUME:/var/lib/postgresql" \
  "$IMAGE"

# Wait for postgres to be ready
echo "Waiting for PostgreSQL to be ready..."
until docker exec "$CONTAINER" pg_isready -U postgres; do
  sleep 1
done

# Install extensions
docker exec "$CONTAINER" psql -U postgres <<'SQL'
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"  SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto     SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgjwt        SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net       SCHEMA extensions;
SQL

# Connect to minikube network for in-cluster access
MINIKUBE_NET=$(docker inspect minikube --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null || true)
if [ -n "$MINIKUBE_NET" ]; then
  docker network connect "$MINIKUBE_NET" "$CONTAINER" 2>/dev/null || true
  MINIKUBE_IP=$(docker inspect "$CONTAINER" --format "{{(index .NetworkSettings.Networks \"$MINIKUBE_NET\").IPAddress}}")
  echo "PostgreSQL is ready on port $PORT (minikube IP: $MINIKUBE_IP)"
else
  echo "PostgreSQL is ready on port $PORT"
fi

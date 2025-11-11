#!/usr/bin/env bash
set -euo pipefail
echo "🚀 Starting deployment..."
if [ ! -f .env ]; then
  echo "❌ .env file not found. Copy .env.example to .env and configure it."
  exit 1
fi
docker compose pull || true
docker compose build --pull --no-cache server
docker compose up -d --remove-orphans
echo "✅ Deployment complete."

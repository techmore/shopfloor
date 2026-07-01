#!/bin/bash
set -euo pipefail

# =============================================================================
# deploy.sh — Deploy via Capistrano
# Usage: ./deploy.sh [environment]
#   ./deploy.sh              # production
#   ./deploy.sh staging      # staging
# =============================================================================

ENV="${1:-production}"

echo "=== Deploying to $ENV ==="
bundle exec cap "$ENV" deploy

echo ""
echo "=== Smoke test ==="
sleep 5
URL="${APP_URL:-https://shopfloor.example.com/up}"
if curl -sSf "$URL" > /dev/null 2>&1; then
  echo "App is healthy at $URL"
  exit 0
else
  echo "WARNING: health check failed at $URL"
  exit 1
fi

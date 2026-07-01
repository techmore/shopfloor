#!/bin/bash
# =============================================================================
# rails-new.sh — Create the Rails project
# =============================================================================
set -euo pipefail

APP_NAME="shopfloor"
APP_DIR="$HOME/$APP_NAME"

if [ -d "$APP_DIR" ]; then
  echo "App directory already exists at $APP_DIR — skipping rails new"
  exit 0
fi

echo "=== Creating Rails app: $APP_NAME ==="
rails new "$APP_NAME" \
  --database=postgresql \
  --css=tailwind \
  --javascript=importmap \
  --skip-test \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-active-storage

echo "=== Done ==="

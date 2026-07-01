#!/bin/bash
# =============================================================================
# bootstrap.sh — Master orchestrator
# Builds the entire Shopfloor Operations Platform from scratch.
# Run this INSIDE the Multipass VM (or any Ubuntu dev environment).
#
# Usage: cd ~ && git clone <repo> app && cd app && ./scripts/bootstrap.sh
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts/bootstrap"
APP_NAME="shopfloor"
APP_DIR="$HOME/$APP_NAME"

echo "=========================================="
echo " Shopfloor Operations Platform — Bootstrap"
echo "=========================================="
echo ""

# --- Pre-flight checks ---
echo "=== Pre-flight checks ==="
for cmd in ruby node psql redis-cli; do
  if ! command -v $cmd &> /dev/null; then
    echo "ERROR: $cmd not found. Run vm-bootstrap.sh first."
    exit 1
  fi
done
echo "ruby:  $(ruby -v)"
echo "node:  $(node -v)"
echo "rails: $(gem list rails | head -1)"
echo ""

# --- Run each phase ---
PHASES=(
  "rails-new"
  "gems"
  "models"
  "auth"
  "frontend"
  "seed"
  "deploy"
)

for phase in "${PHASES[@]}"; do
  echo ""
  echo "=========================================="
  echo " Phase: $phase"
  echo "=========================================="
  bash "$SCRIPT_DIR/$phase.sh"
done

echo ""
echo "=========================================="
echo " Bootstrap complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  cd ~/$APP_NAME"
echo "  rails server"
echo ""
echo "Or start everything with:"
echo "  foreman start"
echo ""
echo "Open http://localhost:3000 in your browser."

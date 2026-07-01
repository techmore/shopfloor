#!/bin/bash
set -euo pipefail

# =============================================================================
# vm-bootstrap.sh — Run inside Multipass VM on first setup
# Usage: chmod +x vm-bootstrap.sh && ./vm-bootstrap.sh
# No Docker — native Ruby + Postgres + Redis
# =============================================================================

echo "=== Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installing system dependencies ==="
sudo apt install -y \
  curl git build-essential libssl-dev libreadline-dev \
  zlib1g-dev libyaml-dev libxml2-dev libxslt1-dev \
  libpq-dev postgresql postgresql-contrib redis-server \
  imagemagick libsqlite3-dev nginx

echo "=== Installing asdf (version manager) ==="
if [ ! -d "$HOME/.asdf" ]; then
  git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf"
fi
echo '. "$HOME/.asdf/asdf.sh"' >> "$HOME/.bashrc"
echo '. "$HOME/.asdf/completions/asdf.bash"' >> "$HOME/.bashrc"
# Source for this session
. "$HOME/.asdf/asdf.sh"

echo "=== Installing Ruby 3.4.1 ==="
asdf plugin add ruby
asdf install ruby 3.4.1
asdf global ruby 3.4.1

echo "=== Installing Node.js 22 ==="
asdf plugin add nodejs
asdf install nodejs 22.14.0
asdf global nodejs 22.14.0

echo "=== Installing Rails + Capistrano ==="
gem install rails bundler
gem install capistrano capistrano-rails capistrano-bundler capistrano-rvm

echo "=== Creating PostgreSQL dev user ==="
sudo -u postgres createuser -s ubuntu 2>/dev/null || true

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Next steps:"
echo "  1. Log out and back in: exit → multipass shell shopfloor-dev"
echo "  2. cd ~/app && bundle install"
echo "  3. rails db:create db:migrate db:seed"
echo "  4. foreman start"

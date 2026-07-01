#!/bin/bash
set -euo pipefail

# =============================================================================
# provision-incus-containers.sh — Run on the Rocky Linux host
# Creates production system containers for app, postgres, redis
# =============================================================================

INCUS="incus"   # or "lxc" if using LXD
NETWORK="incusbr0"

echo "=== Initializing Incus ==="
if ! command -v $INCUS &> /dev/null; then
  echo "Installing Incus..."
  sudo dnf install -y epel-release
  sudo dnf install -y incus incus-client
  sudo systemctl enable --now incus
  sudo usermod -aG incus "$USER"
  echo "Log out and back in, then re-run this script."
  exit 1
fi

echo "=== Launching postgres container ==="
$INCUS launch images:rockylinux/9/cloud postgres
sleep 5
$INCUS exec postgres -- dnf install -y postgresql-server postgresql-contrib
$INCUS exec postgres -- postgresql-setup --initdb
$INCUS exec postgres -- systemctl enable --now postgresql

# Configure postgres to listen on network for app container
$INCUS exec postgres -- bash -c 'echo "listen_addresses = '\''*'\''" >> /var/lib/pgsql/data/postgresql.conf'
$INCUS exec postgres -- bash -c 'echo "host all all 10.0.0.0/8 md5" >> /var/lib/pgsql/data/pg_hba.conf'
$INCUS exec postgres -- systemctl restart postgresql

echo "=== Launching redis container ==="
$INCUS launch images:rockylinux/9/cloud redis
sleep 5
$INCUS exec redis -- dnf install -y redis
$INCUS exec redis -- systemctl enable --now redis

echo "=== Launching app container ==="
$INCUS launch images:rockylinux/9/cloud app
sleep 5
$INCUS exec app -- dnf install -y epel-release
$INCUS exec app -- dnf install -y \
  git curl gcc make libssl-devel libreadline-devel \
  zlib-devel libyaml-devel libxml2-devel libxslt-devel \
  postgresql-devel postgresql redis imagemagick sqlite-devel

echo "=== Installing asdf + Ruby in app container ==="
$INCUS exec app -- bash -c 'git clone https://github.com/asdf-vm/asdf.git ~deploy/.asdf'
$INCUS exec app -- bash -c 'echo '\''. "$HOME/.asdf/asdf.sh"'\'' >> ~deploy/.bashrc'
$INCUS exec app -- bash -c '~deploy/.asdf/bin/asdf plugin add ruby'
$INCUS exec app -- bash -c '~deploy/.asdf/bin/asdf install ruby 3.4.1'
$INCUS exec app -- bash -c '~deploy/.asdf/bin/asdf global ruby 3.4.1'
$INCUS exec app -- bash -c '~deploy/.asdf/bin/asdf plugin add nodejs'
$INCUS exec app -- bash -c '~deploy/.asdf/bin/asdf install nodejs 22.14.0'
$INCUS exec app -- bash -c '~deploy/.asdf/bin/asdf global nodejs 22.14.0'

echo "=== Creating deploy user ==="
$INCUS exec app -- useradd -m -s /bin/bash deploy || true
$INCUS exec app -- bash -c 'echo "deploy ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/deploy'
$INCUS exec app -- mkdir -p /home/deploy/shopfloor
$INCUS exec app -- chown deploy:deploy /home/deploy/shopfloor

echo "=== Firewall ==="
sudo firewall-cmd --permanent --add-port=443/tcp --add-port=80/tcp
sudo firewall-cmd --reload

echo ""
echo "=== Done ==="
echo ""
echo "Container IPs:"
$INCUS list
echo ""
echo "Get app container IP for Capistrano deploy target:"
echo "  $INCUS list app | grep eth0"
echo ""
echo "Then set as server IP in config/deploy/production.rb"

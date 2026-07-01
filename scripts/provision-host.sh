#!/bin/bash
set -euo pipefail

# =============================================================================
# provision-host.sh — Run from Mac or CI to prepare the Rocky Linux host
# Usage: ./provision-host.sh root@10.0.0.50
# =============================================================================

if [ $# -lt 1 ]; then
  echo "Usage: $0 <user@host>"
  echo "Example: $0 root@10.0.0.50"
  exit 1
fi

HOST="$1"

echo "=== Provisioning $HOST ==="

ssh "$HOST" bash -s <<'REMOTE'
  set -euo pipefail

  echo "--- Installing Docker ---"
  dnf install -y dnf-utils
  dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
  dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
  systemctl enable --now docker

  echo "--- Creating data directories ---"
  mkdir -p /data/postgres /data/redis

  echo "--- Configuring firewall ---"
  firewall-cmd --permanent --add-port=5432/tcp
  firewall-cmd --permanent --add-port=6379/tcp
  firewall-cmd --permanent --add-port=443/tcp
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --reload

  echo "--- Setting SELinux booleans ---"
  setsebool -P httpd_can_network_connect 1 || true

  echo "--- Installing Incus (optional) ---"
  dnf install -y epel-release 2>/dev/null || true
  dnf install -y incus incus-client 2>/dev/null || true

  echo "--- Done ---"
  echo "Docker status:"
  systemctl is-active docker
REMOTE

echo ""
echo "=== Host provisioned: $HOST ==="
echo "Next: setup SSH key, then kamal setup"

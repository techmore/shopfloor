#!/bin/bash
set -euo pipefail

# =============================================================================
# setup-weigh-station.sh — Run on the Ubuntu box at each weigh station
# Usage: chmod +x setup-weigh-station.sh && ./setup-weigh-station.sh
# =============================================================================

echo "=== Installing printer drivers ==="
sudo apt update && sudo apt install -y cups printer-driver-zebra

echo "=== Starting CUPS ==="
sudo systemctl enable --now cups

echo ""
echo "=== Available printers ==="
lpinfo -v | grep -i usb || echo "No USB printers found — connect Zebra and re-run"
lpinfo -m | grep -i zebra || true

echo ""
echo "=== To configure the Zebra printer ==="
echo "  1. Open http://localhost:631 (CUPS admin)"
echo "  2. Add printer → select USB Zebra"
echo "  3. Or run:"
echo '     sudo lpadmin -p ZebraLabel -E -v usb://Zebra/... -m drv:///...'
echo ""
echo "=== Test print ==="
echo '  echo "^XA^FO50,50^ADN,36,20^FDSHOPFLOOR^FS^XZ" | lp -d ZebraLabel'
echo ""

echo "=== Setting USB device permissions for scale ==="
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", MODE="0666"' \
  | sudo tee /etc/udev/rules.d/99-scale.rules
sudo udevadm control --reload-rules && sudo udevadm trigger

echo "=== Weigh station setup complete ==="
echo "Open browser to https://shopfloor.example.com/weigh_stations"

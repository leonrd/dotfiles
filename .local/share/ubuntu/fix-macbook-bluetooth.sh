#!/bin/sh
# Bluetooth fixes for MacBook Pro 2015 (MacBookPro11,4) on Ubuntu.
#
# Run as your normal user, NOT with sudo:
#   chmod +x fix-macbook-bluetooth.sh && ./fix-macbook-bluetooth.sh
# Safe to run more than once.

set -eu

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not with sudo. It will ask for your password when needed." >&2
  exit 1
fi

echo "=========================================================="
echo " MacBook Pro 2015 Ubuntu Bluetooth fix"
echo "=========================================================="

# 1. Remove the proprietary Broadcom Wi-Fi drivers, but only if installed.
#    (apt-get purge aborts the script when a package is not in the enabled repos.)
echo "--> Removing bcmwl / b43 drivers if installed..."
for pkg in bcmwl-kernel-source firmware-b43-installer; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    sudo apt-get purge -y "$pkg"
  fi
done

# 2. Wi-Fi (not Bluetooth): board-specific firmware names for the BCM43602.
#    brcmfmac falls back to the generic files anyway; this only links them
#    when the generic file actually exists (plain or .zst-compressed).
echo "--> Linking brcmfmac43602 firmware for MacBookPro11,4 (Wi-Fi)..."
FW=/lib/firmware/brcm
MODEL='Apple Inc.-MacBookPro11,4'
for ext in bin txt; do
  for comp in '' .zst; do
    generic="brcmfmac43602-pcie.$ext$comp"
    if [ -e "$FW/$generic" ]; then
      sudo ln -sf "$generic" "$FW/brcmfmac43602-pcie.$MODEL.$ext$comp"
    fi
  done
done

# 3. Stop the Bluetooth USB device from autosuspending
echo "--> Disabling btusb autosuspend..."
echo 'options btusb enable_autosuspend=0' \
  | sudo tee /etc/modprobe.d/macbook-bluetooth.conf >/dev/null

# 4. Bluetooth policy: power on at boot, faster reconnects
echo "--> Updating /etc/bluetooth/main.conf..."
if [ -f /etc/bluetooth/main.conf ]; then
  sudo sed -i -E \
    -e 's/^#?[[:space:]]*AutoEnable[[:space:]]*=.*/AutoEnable=true/' \
    -e 's/^#?[[:space:]]*FastConnectable[[:space:]]*=.*/FastConnectable=true/' \
    /etc/bluetooth/main.conf
fi

# 5. Reload the Bluetooth driver after every resume from suspend
echo "--> Installing resume hook..."
sudo rm -f /lib/systemd/system-sleep/macbook-bluetooth-fix
sudo tee /usr/lib/systemd/system-sleep/macbook-bluetooth-fix >/dev/null <<'HOOK'
#!/bin/sh
# Reload the MacBook Broadcom Bluetooth driver after resume
case "$1" in
  post)
    echo "Reloading btusb after resume"
    systemctl stop bluetooth
    modprobe -r btusb
    sleep 2
    modprobe btusb
    systemctl start bluetooth
    ;;
esac
HOOK
sudo chmod 755 /usr/lib/systemd/system-sleep/macbook-bluetooth-fix

# 6. Rebuild initramfs in case it carries any of these modules or firmware
echo "--> Updating initramfs (this may take a minute)..."
sudo update-initramfs -u

echo "=========================================================="
echo " Done. Reboot to apply the changes."
echo "=========================================================="
#!/bin/sh
# Bluetooth fixes for MacBook Pro 2015 (MacBookPro11,4) on Ubuntu.
#
# Main fix: the Bluetooth chip often fails to start when its driver (btusb)
# loads early in boot ("hci0: BCM: Reset failed (-110)"). This script keeps
# the chip from being power-managed, stops btusb from loading at boot, and
# loads it a little later instead, resetting the chip harder only if needed.
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

# 3. btusb: no autosuspend, and no automatic loading at boot.
#    "blacklist" only stops automatic loading; "modprobe btusb" still works.
echo "--> Configuring btusb (no autosuspend, delayed loading)..."
sudo tee /etc/modprobe.d/macbook-bluetooth.conf >/dev/null <<'EOF'
# MacBookPro11,4: btusb is loaded later by macbook-bt-load.service
blacklist btusb
options btusb enable_autosuspend=0
EOF

# 4. Keep the Bluetooth chip powered from the moment it appears on USB,
#    including before btusb loads and after the chip is reset.
echo "--> Disabling USB power management for the Bluetooth chip..."
sudo tee /etc/udev/rules.d/99-macbook-bluetooth.rules >/dev/null <<'EOF'
# MacBookPro11,4 Bluetooth (05ac:8290): never autosuspend
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="05ac", ATTR{idProduct}=="8290", ATTR{power/control}="on"
EOF
sudo udevadm control --reload
# TLP, if installed, has its own USB autosuspend; exclude Bluetooth from it
if [ -d /etc/tlp.d ]; then
  echo 'USB_EXCLUDE_BTUSB=1' | sudo tee /etc/tlp.d/50-macbook-bluetooth.conf >/dev/null
fi

# 5. Bluetooth policy: power on at boot, faster reconnects
echo "--> Updating /etc/bluetooth/main.conf..."
if [ -f /etc/bluetooth/main.conf ]; then
  sudo sed -i -E \
    -e 's/^#?[[:space:]]*AutoEnable[[:space:]]*=.*/AutoEnable=true/' \
    -e 's/^#?[[:space:]]*FastConnectable[[:space:]]*=.*/FastConnectable=true/' \
    /etc/bluetooth/main.conf
fi

# 6. Loader: starts the controller, resetting the chip harder only if needed
echo "--> Installing delayed Bluetooth loader..."
sudo tee /usr/local/sbin/macbook-bt-load >/dev/null <<'LOADER'
#!/bin/sh
# Start the MacBookPro11,4 Bluetooth controller, working around
# "hci0: BCM: Reset failed (-110)". Each attempt resets the chip a bit
# harder, and the script stops at the first attempt that works, so a
# working controller (and its connections) is never reset again.

VENDOR=05ac
PRODUCT=8290
port_off=

# Print the sysfs directory of the Bluetooth USB device
usb_dev() {
  for d in /sys/bus/usb/devices/*; do
    if [ "$(cat "$d/idVendor" 2>/dev/null)" = "$VENDOR" ] &&
       [ "$(cat "$d/idProduct" 2>/dev/null)" = "$PRODUCT" ]; then
      echo "$d"
      return 0
    fi
  done
  return 1
}

# Never leave the USB port switched off if this script is stopped midway
cleanup() {
  if [ -n "$port_off" ]; then
    echo 0 > "$port_off/disable" 2>/dev/null
  fi
  exit 1
}
trap cleanup TERM INT

# Wait for the kernel to report how the controller start went.
# $1: start time in seconds since the epoch. Prints ok, fail or unknown.
result_since() {
  n=0
  while [ "$n" -lt 15 ]; do
    log=$(journalctl -k -o cat --since "@$1" 2>/dev/null)
    case $log in
      *"Reset failed"*) echo fail; return ;;
      *"BCM: features"*) echo ok; return ;;
    esac
    sleep 1
    n=$((n + 1))
  done
  echo unknown
}

# Gentlest: reload the driver
reload_driver() {
  modprobe -r btusb 2>/dev/null
  sleep 2
  modprobe btusb
}

# Harder: make the USB device re-enumerate, as if unplugged and replugged
reenumerate() {
  modprobe -r btusb 2>/dev/null
  if d=$(usb_dev); then
    echo 0 > "$d/authorized"
    sleep 2
    echo 1 > "$d/authorized"
    sleep 2
  fi
  modprobe btusb
}

# Hardest: switch the USB port off and on (if the hub supports it)
power_cycle() {
  modprobe -r btusb 2>/dev/null
  if d=$(usb_dev) && [ -e "$d/port/disable" ]; then
    port_off=$(readlink -f "$d/port")
    echo 1 > "$port_off/disable"
    sleep 3
    echo 0 > "$port_off/disable"
    port_off=
    sleep 3   # give the chip time to show up on USB again
  fi
  modprobe btusb
}

i=1
for step in reload_driver reenumerate power_cycle power_cycle; do
  sleep 1   # keep kernel messages of the previous attempt out of this one
  echo "Attempt $i: $step"
  start=$(date +%s)
  $step
  case $(result_since "$start") in
    ok)
      echo "Bluetooth controller is up"
      exit 0
      ;;
    unknown)
      # Don't reset a controller that may well be working
      echo "No start-up result in the kernel log; leaving the controller alone"
      exit 0
      ;;
  esac
  i=$((i + 1))
done

echo "Bluetooth controller did not come up" >&2
exit 1
LOADER
sudo chmod 755 /usr/local/sbin/macbook-bt-load

sudo tee /etc/systemd/system/macbook-bt-load.service >/dev/null <<'EOF'
[Unit]
Description=Load MacBook Bluetooth driver after boot
After=bluetooth.service

[Service]
# Type=exec so a slow retry never holds up the login screen
Type=exec
ExecStartPre=/bin/sleep 5
ExecStart=/usr/local/sbin/macbook-bt-load

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable macbook-bt-load.service

# 7. After resume from suspend, run the loader again (in the background,
#    so it doesn't hold up waking the laptop)
echo "--> Installing resume hook..."
sudo rm -f /lib/systemd/system-sleep/macbook-bluetooth-fix
sudo tee /usr/lib/systemd/system-sleep/macbook-bluetooth-fix >/dev/null <<'HOOK'
#!/bin/sh
# Restart the MacBook Broadcom Bluetooth controller after resume
case "$1" in
  post) systemctl --no-block restart macbook-bt-load.service ;;
esac
HOOK
sudo chmod 755 /usr/lib/systemd/system-sleep/macbook-bluetooth-fix

# 8. Rebuild initramfs so the blacklist also applies there
echo "--> Updating initramfs (this may take a minute)..."
sudo update-initramfs -u

echo "=========================================================="
echo " Done. Reboot to apply the changes."
echo " Check the result with: journalctl -b -u macbook-bt-load"
echo "=========================================================="
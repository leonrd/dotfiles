#!/bin/sh
# One-time setup for the MacBook FaceTime HD camera (Ubuntu/Debian).
# The camera turns on by itself when Meet, Zoom or any other app uses
# "MacBook Camera Fix", and turns off again when the app lets go of it.
#
# Run as your normal user, NOT with sudo:
#   chmod +x facetimehd-install.sh && ./facetimehd-install.sh
# It asks for your password when it needs root.

set -eu

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not with sudo. It will ask for your password when needed." >&2
  exit 1
fi

ME=$(id -un)
SERVICE_NAME=facetimehd-ondemand
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Installing packages"
sudo apt update
sudo apt install -y git curl xz-utils cpio make build-essential dkms psmisc \
  "linux-headers-$(uname -r)" v4l2loopback-dkms v4l2loopback-utils ffmpeg

echo "==> Installing camera firmware"
git clone --depth 1 https://github.com/patjak/facetimehd-firmware.git "$WORKDIR/facetimehd-firmware"
make -C "$WORKDIR/facetimehd-firmware"
sudo make -C "$WORKDIR/facetimehd-firmware" install

echo "==> Building and installing the facetimehd driver (DKMS)"
git clone --depth 1 https://github.com/patjak/facetimehd.git "$WORKDIR/facetimehd"
V=$(sed -n 's/^PACKAGE_VERSION=//p' "$WORKDIR/facetimehd/dkms.conf" | tr -d '"')
printf '    facetimehd version: %s\n' "$V"
# Remove an earlier registration of the same version so re-running the script works
if dkms status -m facetimehd -v "$V" 2>/dev/null | grep -q .; then
  sudo dkms remove -m facetimehd -v "$V" --all
fi
sudo rm -rf "/usr/src/facetimehd-$V"
sudo cp -r "$WORKDIR/facetimehd" "/usr/src/facetimehd-$V"
sudo dkms add -m facetimehd -v "$V"
sudo dkms build -m facetimehd -v "$V"
sudo dkms install -m facetimehd -v "$V" --force

echo "==> Configuring the virtual camera to load at boot"
echo v4l2loopback | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
echo 'options v4l2loopback video_nr=10 card_label="MacBook Camera Fix" exclusive_caps=1' \
  | sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null

echo "==> Removing relay services from earlier setups"
# System-wide service from the first version
if [ -f /etc/systemd/system/facetimehd-relay.service ]; then
  sudo systemctl disable --now facetimehd-relay.service || true
  sudo rm -f /etc/systemd/system/facetimehd-relay.service
fi
# User service from an earlier version of this script
if [ -f "$HOME/.config/systemd/user/facetimehd-relay.service" ]; then
  systemctl --user disable --now facetimehd-relay.service 2>/dev/null || true
  rm -f "$HOME/.config/systemd/user/facetimehd-relay.service"
  systemctl --user daemon-reload 2>/dev/null || true
fi
# This script's own service, if it is being re-run
sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true

echo "==> Loading the drivers now"
sudo modprobe -r v4l2loopback 2>/dev/null || true
sudo modprobe -r facetimehd 2>/dev/null || true
sudo modprobe facetimehd
sudo modprobe v4l2loopback

NEED_RELOGIN=0
if ! id -nG "$ME" | tr ' ' '\n' | grep -qx video; then
  printf '==> Adding %s to the video group\n' "$ME"
  sudo usermod -aG video "$ME"
  NEED_RELOGIN=1
fi

echo "==> Installing the on-demand camera service"
sudo tee /usr/local/bin/facetimehd-ondemand >/dev/null <<'WATCHER'
#!/bin/sh
# Keeps "MacBook Camera Fix" (/dev/video10) available to apps at all times,
# but only opens the real camera (/dev/video0) while an app is reading it.
# While nobody is using it, a black placeholder keeps the virtual camera
# listed in browsers, and the real camera (and its light) stays off.

set -u

CAM=/dev/video0
LOOP=/dev/video10
W=1280
H=720
FPS=30
START_AFTER=2   # seconds an app must hold the camera before it turns on
STOP_AFTER=3    # seconds without any app before it turns off

producer_pid=
mode=
seen=0
gone=0

start_idle() {
  ffmpeg -hide_banner -loglevel error -re \
    -f lavfi -i "color=c=black:s=${W}x${H}:r=${FPS}" \
    -pix_fmt yuv420p -f v4l2 "$LOOP" &
  producer_pid=$!
  mode=idle
  echo "camera off"
}

start_live() {
  ffmpeg -hide_banner -loglevel error -fflags nobuffer -flags low_delay \
    -f v4l2 -input_format yuyv422 -i "$CAM" \
    -vf "scale=${W}:${H},format=yuv420p" -r "$FPS" -f v4l2 "$LOOP" &
  producer_pid=$!
  mode=live
  echo "camera on"
}

stop_producer() {
  if [ -n "$producer_pid" ]; then
    kill "$producer_pid" 2>/dev/null
    wait "$producer_pid" 2>/dev/null
  fi
  producer_pid=
}

# Prints how many processes, other than our own ffmpeg, have the virtual camera open
consumers() {
  count=0
  for pid in $(fuser "$LOOP" 2>/dev/null); do
    [ "$pid" = "$producer_pid" ] || count=$((count + 1))
  done
  echo "$count"
}

trap 'stop_producer; exit 0' TERM INT

until [ -e "$CAM" ] && [ -e "$LOOP" ]; do sleep 1; done
start_idle

while :; do
  sleep 1

  # Restart whatever was running if ffmpeg died (e.g. after suspend/resume)
  if ! kill -s 0 "$producer_pid" 2>/dev/null; then
    if [ "$mode" = live ]; then start_live; else start_idle; fi
    continue
  fi

  n=$(consumers)
  case $mode in
    idle)
      if [ "$n" -gt 0 ]; then seen=$((seen + 1)); else seen=0; fi
      if [ "$seen" -ge "$START_AFTER" ]; then
        stop_producer; start_live; seen=0; gone=0
      fi
      ;;
    live)
      if [ "$n" -eq 0 ]; then gone=$((gone + 1)); else gone=0; fi
      if [ "$gone" -ge "$STOP_AFTER" ]; then
        stop_producer; start_idle; seen=0; gone=0
      fi
      ;;
  esac
done
WATCHER
sudo chmod 755 /usr/local/bin/facetimehd-ondemand

sudo tee "/etc/systemd/system/$SERVICE_NAME.service" >/dev/null <<'EOF'
[Unit]
Description=FaceTime HD camera on demand (MacBook Camera Fix)
After=systemd-modules-load.service

[Service]
ExecStart=/usr/local/bin/facetimehd-ondemand
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"

echo
echo "Done. In Meet or Zoom, choose the camera \"MacBook Camera Fix\"."
echo "The real camera turns on a couple of seconds after an app starts using it,"
echo "and turns off a few seconds after the app stops."
if [ "$NEED_RELOGIN" -eq 1 ]; then
  echo "You were added to the video group: log out and back in (or reboot) before using the camera."
fi
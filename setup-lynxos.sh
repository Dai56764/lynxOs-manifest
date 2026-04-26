#!/bin/bash
# ============================================================
#  LynxOS - setup script for the ArchISO profile
#  Run on Arch Linux / Manjaro / EndeavourOS
#  Usage: bash setup-lynxos.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${CYAN}[LynxOS]${NC} $1"; }
ok() { echo -e "${GREEN}[  OK  ]${NC} $1"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $1"; }
err() { echo -e "${RED}[ ERR  ]${NC} $1"; exit 1; }

info "Installing archiso build dependencies..."
sudo pacman -S --noconfirm --needed archiso inkscape python git >/dev/null 2>&1 || true

BASE="$HOME/lynxos"
BUILDDIR="$HOME/build"
ENABLE_AUR="${LYNXOS_ENABLE_AUR:-false}"

mkdir -p "$BUILDDIR"
info "Working directory: $BUILDDIR"

if [ -d "$BASE" ]; then
    warn "Removing existing profile at $BASE"
    sudo rm -rf "$BASE"
fi

cp -r /usr/share/archiso/configs/releng/ "$BASE"
cd "$BASE"

mkdir -p airootfs/etc/skel/Desktop
mkdir -p airootfs/etc/skel/.config/autostart
mkdir -p airootfs/etc/systemd/system
mkdir -p airootfs/usr/local/bin
mkdir -p airootfs/usr/share/applications
mkdir -p airootfs/usr/share/pixmaps
mkdir -p airootfs/usr/share/icons/hicolor/{16x16,32x32,48x48,128x128,256x256}/apps
mkdir -p airootfs/var/lib
ok "Profile directories created"

cat > profiledef.sh <<'EOF'
#!/usr/bin/env bash

iso_name="lynxos"
iso_label="LYNXOS_1_0"
iso_publisher="LynxOS Team"
iso_application="LynxOS"
iso_version="1.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
  'bios.syslinux'
  'uefi.grub'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=(
  '-comp' 'zstd'
  '-Xcompression-level' '15'
  '-b' '1M'
)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/lynx-firstboot"]="0:0:755"
  ["/usr/local/bin/lynx-gpu-setup"]="0:0:755"
  ["/usr/local/bin/lynx-mirror-update"]="0:0:755"
  ["/usr/local/bin/lynx-system-update"]="0:0:755"
)
EOF
ok "profiledef.sh created"

cat > pacman.conf <<'EOF'
[options]
HoldPkg = pacman glibc
Architecture = auto
ParallelDownloads = 10
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
ok "pacman.conf created"

cat > packages.x86_64 <<'EOF'
base
base-devel
linux
linux-headers
linux-firmware
amd-ucode
intel-ucode
archinstall
bash-completion
blueman
bluez
bluez-utils
btop
curl
dosfstools
e2fsprogs
efibootmgr
exfatprogs
fastfetch
ffmpeg
file-roller
firefox
gdm
git
gnome
gnome-browser-connector
gnome-console
gnome-disk-utility
gnome-shell-extensions
gnome-system-monitor
gnome-text-editor
gnome-tweaks
grub
gstreamer
gst-libav
gst-plugin-pipewire
gst-plugins-bad
gst-plugins-base
gst-plugins-good
gst-plugins-ugly
gzip
htop
inxi
inkscape
less
libisoburn
libva
libva-utils
libvdpau
lsof
mesa
mtools
nano
network-manager-applet
networkmanager
ntfs-3g
os-prober
pavucontrol
pipewire
pipewire-alsa
pipewire-jack
pipewire-pulse
python
reflector
rclone
rsync
sudo
syslinux
squashfs-tools
strace
timeshift
unzip
vim
vulkan-icd-loader
wget
wireplumber
xdg-desktop-portal-gnome
xdg-user-dirs
xorriso
zip
EOF
ok "packages.x86_64 created"

echo "lynxos" > airootfs/etc/hostname
cat > airootfs/etc/os-release <<'EOF'
NAME="LynxOS"
VERSION="1.0"
ID=lynxos
ID_LIKE=arch
PRETTY_NAME="LynxOS 1.0"
VERSION_ID="1.0"
ANSI_COLOR="1;36"
HOME_URL="https://github.com/Dai56764/lynxOs-manifest"
BUILD_ID=rolling
LOGO=lynxos-logo
EOF
ok "Identity files created"

cat > airootfs/etc/default/grub <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="LynxOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER=false
EOF

cat > airootfs/etc/gdm/custom.conf <<'EOF'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=liveuser
WaylandEnable=true
EOF
ok "Display manager configured"

cat > airootfs/etc/skel/Desktop/install-lynxos.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Install LynxOS
Name[ru]=Установить LynxOS
Comment=Launch the Archinstall installer
Comment[ru]=Запустить установщик Archinstall
Exec=kgx -- bash -lc 'archinstall; exec bash'
Icon=system-software-install
Terminal=false
Categories=System;
EOF

cat > airootfs/usr/share/applications/lynx-system-update.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS System Update
Name[ru]=Обновление LynxOS
Comment=Refresh mirrors, upgrade packages and check releases
Comment[ru]=Обновить зеркала, пакеты и проверить релизы
Exec=kgx -- bash -lc 'lynx-system-update; exec bash'
Icon=software-update-available
Terminal=false
Categories=System;Settings;
EOF

cat > airootfs/etc/skel/Desktop/lynx-system-update.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS Update
Name[ru]=Обновить LynxOS
Comment=Refresh mirrors, upgrade packages and check releases
Comment[ru]=Обновить зеркала, пакеты и проверить релизы
Exec=kgx -- bash -lc 'lynx-system-update; exec bash'
Icon=software-update-available
Terminal=false
Categories=System;Settings;
EOF
ok "Desktop launchers created"

cat > airootfs/usr/local/bin/lynx-mirror-update <<'EOF'
#!/bin/bash
set -e
sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
echo "Mirror list updated."
EOF

cat > airootfs/usr/local/bin/lynx-system-update <<'EOF'
#!/bin/bash
set -euo pipefail

STATE_DIR="/var/lib/lynxos"
STATE_FILE="$STATE_DIR/last-release"
mkdir -p "$STATE_DIR"

echo "==> Refreshing mirrors"
if command -v lynx-mirror-update >/dev/null 2>&1; then
  lynx-mirror-update || true
fi

echo "==> Updating packages"
sudo pacman -Syu --noconfirm

echo "==> Checking LynxOS release feed"
latest_tag="$(python - <<'PY'
import json
import urllib.request

url = "https://api.github.com/repos/Dai56764/lynxOs-manifest/releases/latest"
try:
    with urllib.request.urlopen(url, timeout=15) as response:
        payload = json.load(response)
    print(payload.get("tag_name", ""))
except Exception:
    print("")
PY
)"

if [ -n "$latest_tag" ]; then
  previous_tag=""
  [ -f "$STATE_FILE" ] && previous_tag="$(cat "$STATE_FILE")"
  echo "$latest_tag" | sudo tee "$STATE_FILE" >/dev/null

  if [ -n "$previous_tag" ] && [ "$previous_tag" != "$latest_tag" ]; then
    echo "A newer LynxOS release is available: $latest_tag"
    echo "Open: https://github.com/Dai56764/lynxOs-manifest/releases"
  else
    echo "Latest known LynxOS release: $latest_tag"
  fi
else
  echo "Could not fetch release metadata."
fi

echo "Package update finished."
echo "For a fresh ISO install, download the newest image from Releases or Actions artifacts."
EOF

cat > airootfs/usr/local/bin/lynx-gpu-setup <<'EOF'
#!/bin/bash
set -e
touch /var/lib/lynx-gpu-configured
echo "GPU setup completed."
EOF

cat > airootfs/usr/local/bin/lynx-firstboot <<'EOF'
#!/bin/bash
set -e

os-prober >/dev/null 2>&1 || true
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || true
xdg-user-dirs-update >/dev/null 2>&1 || true
dconf update >/dev/null 2>&1 || true

touch /var/lib/lynx-firstboot-done
systemctl disable lynx-firstboot.service >/dev/null 2>&1 || true
echo "First boot tasks completed."
EOF
ok "Helper scripts created"

cat > airootfs/etc/systemd/system/lynx-gpu-setup.service <<'EOF'
[Unit]
Description=LynxOS GPU setup
ConditionPathExists=!/var/lib/lynx-gpu-configured

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lynx-gpu-setup

[Install]
WantedBy=multi-user.target
EOF

cat > airootfs/etc/systemd/system/lynx-firstboot.service <<'EOF'
[Unit]
Description=LynxOS first boot tasks
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/lynx-firstboot-done

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lynx-firstboot

[Install]
WantedBy=multi-user.target
EOF
ok "Systemd units created"

cat > airootfs/root/customize_airootfs.sh <<EOF
#!/bin/bash
set -euo pipefail

echo "==> LynxOS customize_airootfs"

echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

useradd -m -G wheel,audio,video,storage,network -s /bin/bash liveuser 2>/dev/null || true
echo "liveuser:liveuser" | chpasswd
install -d /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/lynxos-wheel
chmod 440 /etc/sudoers.d/lynxos-wheel

systemctl enable gdm
systemctl enable NetworkManager
systemctl enable bluetooth >/dev/null 2>&1 || true
systemctl enable lynx-gpu-setup.service
systemctl enable lynx-firstboot.service

chmod +x /usr/local/bin/lynx-firstboot
chmod +x /usr/local/bin/lynx-gpu-setup
chmod +x /usr/local/bin/lynx-mirror-update
chmod +x /usr/local/bin/lynx-system-update
chmod +x /home/liveuser/Desktop/install-lynxos.desktop 2>/dev/null || true
chmod +x /home/liveuser/Desktop/lynx-system-update.desktop 2>/dev/null || true
chmod +x /etc/skel/Desktop/install-lynxos.desktop 2>/dev/null || true
chmod +x /etc/skel/Desktop/lynx-system-update.desktop 2>/dev/null || true

if [ "${ENABLE_AUR}" = "true" ]; then
  echo "==> Building optional AUR packages"
  useradd -m -s /bin/bash aurbuilder 2>/dev/null || true
  echo "aurbuilder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/aurbuilder
  chmod 440 /etc/sudoers.d/aurbuilder
  install -d -o aurbuilder -g aurbuilder /tmp/aurbuild

  sudo -u aurbuilder git clone --depth=1 https://aur.archlinux.org/google-chrome.git /tmp/aurbuild/google-chrome || true
  if [ -d /tmp/aurbuild/google-chrome ]; then
    cd /tmp/aurbuild/google-chrome
    sudo -u aurbuilder makepkg -si --noconfirm || echo "google-chrome build failed, continuing"
    cd /
  else
    echo "google-chrome source unavailable, continuing"
  fi

  rm -rf /tmp/aurbuild
  userdel -r aurbuilder >/dev/null 2>&1 || true
  rm -f /etc/sudoers.d/aurbuilder
fi

pacman -Sc --noconfirm >/dev/null 2>&1 || true
echo "==> customize_airootfs finished"
EOF
chmod +x airootfs/root/customize_airootfs.sh
ok "customize_airootfs.sh created"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SVG_SRC="$SCRIPT_DIR/lynxos-logo.svg"

if [ -f "$SVG_SRC" ] && command -v inkscape >/dev/null 2>&1; then
    info "Rendering logo assets from SVG"
    for SIZE in 16 32 48 128 256; do
        inkscape "$SVG_SRC" \
            --export-filename="$BUILDDIR/lynxos-logo-${SIZE}.png" \
            --export-width="$SIZE" \
            --export-height="$SIZE" >/dev/null 2>&1
        cp "$BUILDDIR/lynxos-logo-${SIZE}.png" \
            "airootfs/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/lynxos-logo.png"
    done
    cp "$BUILDDIR/lynxos-logo-256.png" airootfs/usr/share/pixmaps/lynxos-logo.png
    ok "Logo assets generated"
else
    warn "SVG logo not converted automatically"
fi

echo
echo -e "${GREEN}LynxOS profile is ready.${NC}"
echo -e "Run ${CYAN}bash build-lynxos.sh${NC} to build the ISO."

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
sudo pacman -S --noconfirm --needed archiso inkscape python git reflector >/dev/null 2>&1 || true

BASE="$HOME/lynxos"
BUILDDIR="$HOME/build"
ENABLE_AUR="${LYNXOS_ENABLE_AUR:-false}"

info "Generating fresh mirrorlist for ArchISO build..."
sudo reflector --latest 20 --sort rate --protocol https --save /etc/pacman.d/mirrorlist >/dev/null 2>&1 || true
mkdir -p "$HOME/.cache/lynxos"
cp /etc/pacman.d/mirrorlist "$HOME/.cache/lynxos/mirrorlist" 2>/dev/null || true

mkdir -p "$BUILDDIR"
info "Working directory: $BUILDDIR"

if [ -d "$BASE" ]; then
    warn "Removing existing profile at $BASE"
    sudo rm -rf "$BASE"
fi

cp -r /usr/share/archiso/configs/releng/ "$BASE"
cp /etc/pacman.d/mirrorlist "$BASE/pacman.d/mirrorlist" 2>/dev/null || true
mkdir -p "$BASE/airootfs/etc/pacman.d"
cp /etc/pacman.d/mirrorlist "$BASE/airootfs/etc/pacman.d/mirrorlist" 2>/dev/null || true
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

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
ok "pacman.conf created"

cat > packages.x86_64 <<'EOF'
# ═══════════════════════════════════════════════════════════
#  БАЗОВЫЕ КОМПОНЕНТЫ
# ═══════════════════════════════════════════════════════════
base
base-devel
sudo
linux-zen
linux-zen-headers
linux-firmware
amd-ucode
intel-ucode

# ═══════════════════════════════════════════════════════════
#  ЗАГРУЗЧИК И РАЗДЕЛЫ
# ═══════════════════════════════════════════════════════════
grub
efibootmgr
parted
gptfdisk
os-prober
dosfstools
e2fsprogs
exfatprogs
mtools
ntfs-3g

# ═══════════════════════════════════════════════════════════
#  СЕТЬ И КОММУНИКАЦИЯ
# ═══════════════════════════════════════════════════════════
networkmanager
network-manager-applet
curl
wget

# ═══════════════════════════════════════════════════════════
#  ОКРУЖЕНИЕ GNOME
# ═══════════════════════════════════════════════════════════
gdm
gnome
gnome-console
gnome-shell
gnome-shell-extensions
gnome-tweaks
gnome-system-monitor
gnome-text-editor
gnome-disk-utility
gnome-browser-connector
xdg-desktop-portal-gnome
xdg-user-dirs

# ═══════════════════════════════════════════════════════════
#  УСТАНОВЩИК (Calamares)
# ═══════════════════════════════════════════════════════════
calamares
kpmcore
partitionmanager

# ═══════════════════════════════════════════════════════════
#  ТЕКСТОВЫЕ РЕДАКТОРЫ И УТИЛИТЫ
# ═══════════════════════════════════════════════════════════
nano
vim
bash-completion

# ═══════════════════════════════════════════════════════════
#  ВЕРСИОННЫЙ КОНТРОЛЬ И РАЗВИТИЕ
# ═══════════════════════════════════════════════════════════
git
python
python-pip
gcc
gdb
make
cmake
clang
llvm

# ═══════════════════════════════════════════════════════════
#  ШРИФТЫ (качественные)
# ═══════════════════════════════════════════════════════════
noto-fonts
noto-fonts-emoji
noto-fonts-cjk
ttf-liberation
ttf-dejavu
ttf-jetbrains-mono
ttf-fira-code
ttf-fira-sans
cantarell-fonts
ttf-opensans

# ═══════════════════════════════════════════════════════════
#  АУДИО И МУЛЬТИМЕДИА
# ═══════════════════════════════════════════════════════════
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
wireplumber
pavucontrol
ffmpeg
gstreamer
gst-libav
gst-plugin-pipewire
gst-plugins-bad
gst-plugins-base
gst-plugins-good
gst-plugins-ugly

# ═══════════════════════════════════════════════════════════
#  ГРАФИКА И ВИДЕО
# ═══════════════════════════════════════════════════════════
mesa
vulkan-icd-loader
libva
libva-utils
libvdpau
libxvmc

# ═══════════════════════════════════════════════════════════
#  ДРАЙВЕРЫ ГРАФИКИ (Intel, NVIDIA, AMD)
# ═══════════════════════════════════════════════════════════
# Intel
intel-media-driver
libva-intel-driver
intel-gpu-tools

# NVIDIA (все варианты)
nvidia
nvidia-utils
nvidia-settings
cuda

# AMD
xf86-video-amdgpu
libva-mesa-driver
mesa-vdpau
amdvlk

# ═══════════════════════════════════════════════════════════
#  ПЕРЕКЛЮЧАТЕЛЬ ВИДЕОКАРТ
# ═══════════════════════════════════════════════════════════
switcheroo-control

# ═══════════════════════════════════════════════════════════
#  МОНИТОРИНГ И СИСТЕМНЫЕ УТИЛИТЫ
# ═══════════════════════════════════════════════════════════
btop
htop
fastfetch
lsof
strace
inxi
hwinfo
dmidecode
acpi
lm_sensors
cpupower

# ═══════════════════════════════════════════════════════════
#  КОМПРЕССИЯ И АРХИВЫ
# ═══════════════════════════════════════════════════════════
unzip
zip
gzip
bzip2
xz
file-roller
libarchive

# ═══════════════════════════════════════════════════════════
#  ISO, АРХИВИРОВАНИЕ И СИНХРОНИЗАЦИЯ
# ═══════════════════════════════════════════════════════════
libisoburn
xorriso
archinstall
timeshift
rsync
rclone

# ═══════════════════════════════════════════════════════════
#  ОСТАЛЬНОЕ
# ═══════════════════════════════════════════════════════════
squashfs-tools
syslinux
reflector
bluez
bluez-utils
blueman
firefox
inkscape
less
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

mkdir -p airootfs/etc/default
mkdir -p airootfs/etc/gdm

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

cat > airootfs/usr/share/applications/lynx-recommended-apps.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS Recommended Apps
Name[ru]=Рекомендуемые приложения
Comment=Install recommended applications for LynxOS
Comment[ru]=Установить рекомендуемые приложения
Exec=gnome-terminal -- bash -lc 'lynx-recommended-apps; exec bash'
Icon=application-x-executable
Terminal=false
Categories=System;Settings;
StartupNotify=true
EOF

cat > airootfs/usr/share/applications/lynx-github-update.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS GitHub Update
Name[ru]=Обновление LynxOS
Comment=Check and download updates from GitHub
Comment[ru]=Проверить и загрузить обновления с GitHub
Exec=gnome-terminal -- bash -lc 'lynx-github-update; exec bash'
Icon=software-update-available
Terminal=false
Categories=System;Settings;
StartupNotify=true
EOF

cat > airootfs/usr/share/applications/lynx-iso-tool.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS ISO Tool
Name[ru]=Инструмент ISO
Comment=Manage ISO images - write to USB, test in QEMU
Comment[ru]=Управление ISO - запись на USB, тестирование в QEMU
Exec=gnome-terminal -- bash -lc 'lynx-iso-tool; exec bash'
Icon=media-cdrom
Terminal=false
Categories=System;Utilities;
StartupNotify=true
EOF
ok "Application launchers created"

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

# Запуск рекомендуемых приложений при первой загрузке
sudo -u liveuser timeout 2 /usr/local/bin/lynx-recommended-apps 2>/dev/null || true

touch /var/lib/lynx-firstboot-done
systemctl disable lynx-firstboot.service >/dev/null 2>&1 || true
echo "First boot tasks completed."
EOF

cat > airootfs/usr/local/bin/lynx-recommended-apps << 'APPEOF'
#!/bin/bash
set -euo pipefail
STATE_DIR="${HOME}/.local/share/lynxos"
RECOMMENDED_SHOWN_FILE="${STATE_DIR}/recommended-shown"
mkdir -p "$STATE_DIR"
if [ -f "$RECOMMENDED_SHOWN_FILE" ]; then
    exit 0
fi
command -v zenity &>/dev/null || sudo pacman -S --noconfirm zenity >/dev/null 2>&1 || exit 0
zenity --info \
    --title="LynxOS — Добро пожаловать! 🎉" \
    --text="Добро пожаловать в LynxOS!\n\nВы можете установить дополнительные приложения.\n\nОткройте 'Рекомендуемые приложения' из меню." \
    --width=400 --height=200 2>/dev/null || true
touch "$RECOMMENDED_SHOWN_FILE"
APPEOF

cat > airootfs/usr/local/bin/lynx-github-update << 'GHEOF'
#!/bin/bash
set -euo pipefail
REPO="${LYNXOS_REPO:-Dai56764/lynxOs-manifest}"
CACHE_DIR="${HOME}/.cache/lynxos"
STATE_DIR="${HOME}/.local/share/lynxos"
mkdir -p "$CACHE_DIR" "$STATE_DIR"
echo "LynxOS GitHub Update Tool"
echo "Repository: $REPO"
echo ""
echo "Available commands:"
echo "  lynx-github-update fetch     - Fetch release info"
echo "  lynx-github-update list      - List available releases"
echo "  lynx-github-update download  - Download latest ISO"
echo "  lynx-github-update apply FILE - Apply ISO/archive update"
echo ""
echo "For more info: https://github.com/$REPO"
GHEOF

cat > airootfs/usr/local/bin/lynx-iso-tool << 'ISOEOF'
#!/bin/bash
set -euo pipefail
echo "LynxOS ISO Tool"
echo ""
echo "Available commands:"
echo "  lynx-iso-tool list-usb      - List USB devices"
echo "  lynx-iso-tool write-dd ISO DEV - Write ISO to USB"
echo "  lynx-iso-tool test-qemu ISO   - Test ISO in QEMU"
echo "  lynx-iso-tool info ISO        - Show ISO info"
echo ""
ISOEOF
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

# Добавление новых скриптов инструментов
if [ -f "/usr/local/bin/lynx-recommended-apps" ]; then
  chmod +x /usr/local/bin/lynx-recommended-apps
fi
if [ -f "/usr/local/bin/lynx-github-update" ]; then
  chmod +x /usr/local/bin/lynx-github-update
fi
if [ -f "/usr/local/bin/lynx-iso-tool" ]; then
  chmod +x /usr/local/bin/lynx-iso-tool
fi

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

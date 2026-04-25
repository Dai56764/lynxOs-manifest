#!/bin/bash
# ============================================================
#  LynxOS — Скрипт создания структуры проекта (v2 FIXED)
#  Запускать на Arch Linux / Manjaro / EndeavourOS
#  Использование: bash setup-lynxos.sh
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${CYAN}[LynxOS]${NC} $1"; }
ok()    { echo -e "${GREEN}[  OK  ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[ WARN ]${NC} $1"; }
err()   { echo -e "${RED}[ ERR  ]${NC} $1"; exit 1; }

info "Установка archiso и зависимостей..."
sudo pacman -S --noconfirm --needed archiso inkscape python 2>/dev/null || true

BASE="$HOME/lynxos"
# ~/build вместо /tmp — чтобы не заполнять tmpfs в RAM
BUILDDIR="$HOME/build"
mkdir -p "$BUILDDIR"
info "Временные файлы будут в: $BUILDDIR (НЕ в /tmp)"

if [ -d "$BASE" ]; then
    warn "Папка $BASE уже существует. Удаляем..."
    sudo rm -rf "$BASE"
fi

info "Копирование базового профиля archiso..."
cp -r /usr/share/archiso/configs/releng/ "$BASE"
cd "$BASE"

# ─────────────────────────────────────────────
#  СТРУКТУРА ПАПОК
# ─────────────────────────────────────────────
mkdir -p airootfs/etc/{calamares/branding/lynxos,dconf/db/local.d,\
skel/.config/{gtk-3.0,gtk-4.0},skel/Desktop,systemd/system,\
modprobe.d,default,gdm,fonts}
mkdir -p airootfs/usr/local/{bin,share/lynxos-welcome}
mkdir -p airootfs/usr/share/{pixmaps,fonts/lynxos}
mkdir -p airootfs/usr/share/icons/hicolor/{16x16,32x32,48x48,128x128,256x256}/apps
mkdir -p airootfs/usr/share/applications
mkdir -p airootfs/root
mkdir -p airootfs/var/lib
ok "Структура папок создана"

# ─────────────────────────────────────────────
#  profiledef.sh
# ─────────────────────────────────────────────
cat > profiledef.sh << 'EOF'
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
  ["/usr/local/bin/lynx-gpu-setup"]="0:0:755"
  ["/usr/local/bin/lynx-firstboot"]="0:0:755"
  ["/usr/local/bin/lynx-welcome"]="0:0:755"
  ["/usr/local/bin/lynx-mirror-update"]="0:0:755"
)
EOF
ok "profiledef.sh создан"

# ─────────────────────────────────────────────
#  pacman.conf — ИСПРАВЛЕННЫЙ
# ─────────────────────────────────────────────
cat > pacman.conf << 'EOF'
[options]
HoldPkg      = pacman glibc
Architecture = auto
SigLevel    = Never
LocalFileSigLevel = Never

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
ok "pacman.conf создан"

# ─────────────────────────────────────────────
#  packages.x86_64
# ─────────────────────────────────────────────
cat > packages.x86_64 << 'EOF'
linux-zen
linux-zen-headers
linux-firmware
amd-ucode
intel-ucode
syslinux
base
base-devel
sudo
nano
vim
wget
curl
git
bash-completion
networkmanager
network-manager-applet
ntfs-3g
dosfstools
e2fsprogs
exfatprogs
os-prober
efibootmgr
grub
parted
gptfdisk
gnome
gnome-extra
gdm
gnome-tweaks
gnome-shell-extensions
gnome-browser-connector
xdg-user-dirs
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
btop
htop
fastfetch
lsof
strace
inxi
hwinfo
dmidecode
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
wireplumber
pavucontrol
gstreamer
gst-plugins-base
gst-plugins-good
gst-plugins-bad
gst-plugins-ugly
gst-plugin-pipewire
gst-libav
ffmpeg
libva
libva-utils
libvdpau
mesa
lib32-mesa
vulkan-radeon
lib32-vulkan-radeon
libva-mesa-driver
xf86-video-amdgpu
nvidia-dkms
nvidia-utils
lib32-nvidia-utils
nvidia-settings
vulkan-intel
lib32-vulkan-intel
intel-media-driver
vulkan-icd-loader
lib32-vulkan-icd-loader
steam
lutris
wine
wine-mono
gamemode
lib32-gamemode
mangohud
lib32-mangohud
firefox
rclone
archinstall
boost-libs
kpmcore
python
python-jsonschema
rsync
squashfs-tools
qt5-base
qt5-svg
qt5-wayland
qt6-wayland
xdg-desktop-portal-gnome
EOF
ok "packages.x86_64 создан"

echo "lynxos" > airootfs/etc/hostname
cat > airootfs/etc/os-release << 'EOF'
NAME="LynxOS"
VERSION="1.0"
ID=lynxos
ID_LIKE=arch
PRETTY_NAME="LynxOS 1.0"
VERSION_ID="1.0"
ANSI_COLOR="1;36"
HOME_URL="https://lynxos.example.com"
BUILD_ID=rolling
LOGO=lynxos-logo
EOF
ok "os-release и hostname настроены"

cat > airootfs/etc/default/grub << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="LynxOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER=false
GRUB_GFXMODE=1920x1080,auto
GRUB_GFXPAYLOAD_LINUX=keep
EOF
ok "GRUB настроен"

cat > airootfs/etc/gdm/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=liveuser
WaylandEnable=true

[security]
[xdmcp]
[chooser]
[debug]
EOF
ok "GDM автовход настроен"

mkdir -p airootfs/etc/skel/.config/fastfetch
cat > airootfs/etc/skel/.config/fastfetch/config.jsonc << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "auto",
    "color": { "1": "cyan", "2": "blue" }
  },
  "display": {
    "separator": " -> "
  },
  "modules": [
    "title", "separator",
    "os", "host", "kernel", "uptime",
    "packages", "shell", "display",
    "de", "wm", "theme", "icons", "font",
    "separator",
    "cpu", "gpu", "memory", "swap", "disk",
    "separator",
    "battery", "poweradapter", "locale",
    "separator",
    "colors"
  ]
}
EOF
ok "fastfetch конфиг создан"

cat > airootfs/etc/skel/Desktop/install-lynxos.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Установить LynxOS
Name[ru]=Установить LynxOS
Comment=Запустить установщик Archinstall
Exec=kgx -- bash -lc 'archinstall; exec bash'
Icon=lynxos-logo
Terminal=false
Categories=System;
EOF

cat > airootfs/usr/local/bin/lynx-welcome << 'WELCOME_EOF'
#!/usr/bin/env python3
import gi, subprocess, threading
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib

APP_CSS = """
window { background-color: #0d1117; }
.welcome-title { font-size: 32px; font-weight: bold; color: #00bcd4; }
.welcome-sub { font-size: 14px; color: #8b949e; }
"""

def run_cmd(cmd, callback=None):
    def _run():
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
            if callback:
                GLib.idle_add(callback, result.returncode == 0, result.stdout + result.stderr)
        except Exception as e:
            if callback:
                GLib.idle_add(callback, False, str(e))
    threading.Thread(target=_run, daemon=True).start()

class LynxWelcome(Adw.Application):
    def __init__(self):
        super().__init__(application_id="com.lynxos.welcome")
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        provider = Gtk.CssProvider()
        provider.load_from_data(APP_CSS.encode())
        win = Adw.ApplicationWindow(application=app)
        win.set_title("Добро пожаловать в LynxOS")
        win.set_default_size(780, 620)
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.set_margin_top(32)
        main_box.set_margin_bottom(24)
        main_box.set_margin_start(32)
        main_box.set_margin_end(32)
        title = Gtk.Label(label="Добро пожаловать в LynxOS")
        title.add_css_class("welcome-title")
        main_box.append(title)
        sub = Gtk.Label(label="Быстрые действия для настройки системы")
        sub.add_css_class("welcome-sub")
        sub.set_margin_bottom(28)
        main_box.append(sub)
        win.set_content(main_box)
        win.present()
WELCOME_EOF

chmod +x airootfs/usr/local/bin/lynx-welcome
ok "welcome app создан"

cat > airootfs/usr/share/applications/lynx-welcome.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS Welcome
Exec=/usr/local/bin/lynx-welcome
Icon=lynxos-logo
Terminal=false
Categories=System;
EOF

mkdir -p airootfs/etc/skel/.config/autostart
cat > airootfs/etc/skel/.config/autostart/lynx-welcome.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS Welcome
Exec=/usr/local/bin/lynx-welcome
Icon=lynxos-logo
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

cat > airootfs/usr/local/bin/lynx-mirror-update << 'EOF'
#!/bin/bash
sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
EOF
chmod +x airootfs/usr/local/bin/lynx-mirror-update

cat > airootfs/usr/local/bin/lynx-gpu-setup << 'EOF'
#!/bin/bash
echo "GPU setup placeholder"
EOF
chmod +x airootfs/usr/local/bin/lynx-gpu-setup

cat > airootfs/usr/local/bin/lynx-firstboot << 'EOF'
#!/bin/bash
echo "firstboot placeholder"
EOF
chmod +x airootfs/usr/local/bin/lynx-firstboot

cat > airootfs/etc/systemd/system/lynx-gpu-setup.service << 'EOF'
[Unit]
Description=LynxOS GPU Auto-Setup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lynx-gpu-setup

[Install]
WantedBy=multi-user.target
EOF

cat > airootfs/etc/systemd/system/lynx-firstboot.service << 'EOF'
[Unit]
Description=LynxOS First Boot Setup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lynx-firstboot

[Install]
WantedBy=multi-user.target
EOF

mkdir -p airootfs/boot/grub/themes/lynxos
cat > airootfs/boot/grub/themes/lynxos/theme.txt << 'EOF'
title-text: ""
desktop-color: "#0d1117"
EOF

echo 'GRUB_THEME="/boot/grub/themes/lynxos/theme.txt"' >> airootfs/etc/default/grub

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SVG_SRC="$SCRIPT_DIR/lynxos-logo.svg"
if [ -f "$SVG_SRC" ] && command -v inkscape &>/dev/null; then
    for SIZE in 16 32 48 128 256; do
        inkscape "$SVG_SRC" --export-filename="$BUILDDIR/lynxos-logo-${SIZE}.png" --export-width=$SIZE --export-height=$SIZE 2>/dev/null
        cp "$BUILDDIR/lynxos-logo-${SIZE}.png" "$BASE/airootfs/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/lynxos-logo.png"
    done
    cp "$BUILDDIR/lynxos-logo-256.png" "$BASE/airootfs/usr/share/pixmaps/lynxos-logo.png"
    cp "$BUILDDIR/lynxos-logo-256.png" "$BASE/airootfs/etc/calamares/branding/lynxos/lynxos-logo.png"
fi

echo ""
echo -e "${GREEN}LynxOS structure is ready${NC}"
echo -e "  ${CYAN}bash build-lynxos.sh${NC}"

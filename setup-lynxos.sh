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
#  SigLevel = Never, без chaotic-aur в списке
#  (chaotic-aur устанавливается в хуке)
# ─────────────────────────────────────────────
cat > pacman.conf << 'EOF'
[options]
HoldPkg      = pacman glibc
Architecture = auto

# SigLevel = Never — чтобы не зависало на выборе пакетов
SigLevel    = Never
LocalFileSigLevel = Never

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
ok "pacman.conf создан (SigLevel=Never, без chaotic-aur в списке)"

# ─────────────────────────────────────────────
#  packages.x86_64 — ИСПРАВЛЕННЫЙ
#  Убраны: mesa-vdpau (входит в mesa), adw-gtk3 (AUR→хук),
#           qt5-webengine (убрана зависимость calamares),
#           linux-zen (заменён на linux если нет extra-репо)
#  Добавлены: syslinux, btop, htop, fastfetch, кодеки, шрифты и пр.
# ─────────────────────────────────────────────
cat > packages.x86_64 << 'EOF'
# ═══════════════════════════════════════════
#  ЯДРО И ЗАГРУЗЧИК
# ═══════════════════════════════════════════
linux66
linux66-headers
linux-firmware
amd-ucode
intel-ucode
syslinux

# ═══════════════════════════════════════════
#  БАЗА СИСТЕМЫ
# ═══════════════════════════════════════════
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

# ═══════════════════════════════════════════
#  GNOME (полный)
# ═══════════════════════════════════════════
gnome
gnome-extra
gdm
gnome-tweaks
gnome-shell-extensions
gnome-browser-connector
xdg-user-dirs

# ═══════════════════════════════════════════
#  ШРИФТЫ (качественные)
# ═══════════════════════════════════════════
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

# ═══════════════════════════════════════════
#  МОНИТОРИНГ И СИСТЕМНЫЕ УТИЛИТЫ
# ═══════════════════════════════════════════
btop
htop
fastfetch
lsof
strace
inxi
hwinfo
dmidecode

# ═══════════════════════════════════════════
#  АУДИО
# ═══════════════════════════════════════════
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
wireplumber
pavucontrol

# ═══════════════════════════════════════════
#  ПОЛНЫЙ НАБОР МУЛЬТИМЕДИЙНЫХ КОДЕКОВ
# ═══════════════════════════════════════════
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

# ═══════════════════════════════════════════
#  GPU — AMD
# ═══════════════════════════════════════════
mesa
lib32-mesa
vulkan-radeon
lib32-vulkan-radeon
libva-mesa-driver
xf86-video-amdgpu

# ═══════════════════════════════════════════
#  GPU — NVIDIA
# ═══════════════════════════════════════════
nvidia-dkms
nvidia-utils
lib32-nvidia-utils
nvidia-settings

# ═══════════════════════════════════════════
#  GPU — INTEL
# ═══════════════════════════════════════════
vulkan-intel
lib32-vulkan-intel
intel-media-driver

# ═══════════════════════════════════════════
#  GPU — ОБЩЕЕ (Vulkan)
# ═══════════════════════════════════════════
vulkan-icd-loader
lib32-vulkan-icd-loader

# ═══════════════════════════════════════════
#  ИГРЫ
# ═══════════════════════════════════════════
steam
lutris
wine
wine-mono
gamemode
lib32-gamemode
mangohud
lib32-mangohud

# ═══════════════════════════════════════════
#  БРАУЗЕР
# ═══════════════════════════════════════════
firefox

# ═══════════════════════════════════════════
#  ОБЛАКО И ПЕРЕДАЧА ФАЙЛОВ
# ═══════════════════════════════════════════
rclone

# ═══════════════════════════════════════════
#  AUR HELPER (yay собирается в хуке)
# ═══════════════════════════════════════════
# yay — устанавливается через customize_airootfs.sh

# ═══════════════════════════════════════════
#  CALAMARES (графический установщик)
# ═══════════════════════════════════════════
calamares
boost-libs
kpmcore
python
python-jsonschema
rsync
squashfs-tools
qt5-base
qt5-svg

# ═══════════════════════════════════════════
#  GTK / QT СОВМЕСТИМОСТЬ
# ═══════════════════════════════════════════
qt5-wayland
qt6-wayland
xdg-desktop-portal-gnome
EOF
ok "packages.x86_64 создан (все проблемные пакеты исправлены)"

# ─────────────────────────────────────────────
#  os-release
# ─────────────────────────────────────────────
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

echo "lynxos" > airootfs/etc/hostname
ok "os-release и hostname настроены"

# ─────────────────────────────────────────────
#  GRUB
# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
#  GDM — автовход liveuser
# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
#  DCONF — тема, teal акцент
# ─────────────────────────────────────────────
cat > airootfs/etc/dconf/db/local.d/01-lynxos-theme << 'EOF'
[org/gnome/desktop/interface]
accent-color='teal'
color-scheme='prefer-dark'
icon-theme='Papirus-Dark'
cursor-theme='Adwaita'
font-name='Noto Sans 11'
monospace-font-name='JetBrains Mono 11'
document-font-name='Noto Sans 11'

[org/gnome/desktop/background]
color-shading-type='solid'
primary-color='#0d1117'

[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:'
EOF
ok "Тема LynxOS (teal, тёмная) настроена"

# ─────────────────────────────────────────────
#  fastfetch конфиг
# ─────────────────────────────────────────────
mkdir -p airootfs/etc/skel/.config/fastfetch
cat > airootfs/etc/skel/.config/fastfetch/config.jsonc << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "auto",
    "color": { "1": "cyan", "2": "blue" }
  },
  "display": {
    "separator": " → "
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

# ─────────────────────────────────────────────
#  ЯРЛЫК Calamares
# ─────────────────────────────────────────────
cat > airootfs/etc/skel/Desktop/install-lynxos.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Установить LynxOS
Name[ru]=Установить LynxOS
Comment=Запустить графический установщик LynxOS
Exec=pkexec calamares
Icon=lynxos-logo
Terminal=false
Categories=System;
EOF

# ─────────────────────────────────────────────
#  WELCOME APP — Python/GTK4
# ─────────────────────────────────────────────
cat > airootfs/usr/local/bin/lynx-welcome << 'WELCOME_EOF'
#!/usr/bin/env python3
"""
LynxOS Welcome — экран приветствия
Зависимости: python-gobject (уже в gnome)
"""
import gi, subprocess, threading, os
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib, Pango

APP_CSS = """
window {
  background-color: #0d1117;
}
.welcome-title {
  font-size: 32px;
  font-weight: bold;
  color: #00bcd4;
}
.welcome-sub {
  font-size: 14px;
  color: #8b949e;
}
.card {
  background-color: #161b22;
  border-radius: 12px;
  border: 1px solid #21262d;
  padding: 16px;
}
.action-btn {
  background-color: #00bcd4;
  color: #0d1117;
  font-weight: bold;
  border-radius: 8px;
  padding: 8px 16px;
}
.action-btn:hover {
  background-color: #4dd0e1;
}
.status-ok   { color: #3fb950; }
.status-warn { color: #d29922; }
"""

def run_cmd(cmd, callback=None):
    def _run():
        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=60
            )
            if callback:
                GLib.idle_add(callback, result.returncode == 0,
                              result.stdout + result.stderr)
        except Exception as e:
            if callback:
                GLib.idle_add(callback, False, str(e))
    threading.Thread(target=_run, daemon=True).start()


class LynxWelcome(Adw.Application):
    def __init__(self):
        super().__init__(application_id="com.lynxos.welcome")
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        # CSS
        provider = Gtk.CssProvider()
        provider.load_from_data(APP_CSS.encode())
        Gtk.StyleContext.add_provider_for_display(
            app.get_active_window().get_display() if app.get_active_window()
            else Gtk.Widget.get_display(Gtk.Window()),
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        win = Adw.ApplicationWindow(application=app)
        win.set_title("Добро пожаловать в LynxOS")
        win.set_default_size(780, 620)
        win.set_resizable(False)

        # Главный контейнер
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.set_margin_top(32)
        main_box.set_margin_bottom(24)
        main_box.set_margin_start(32)
        main_box.set_margin_end(32)

        # Заголовок
        title = Gtk.Label(label="🐱 Добро пожаловать в LynxOS")
        title.add_css_class("welcome-title")
        title.set_margin_bottom(6)
        main_box.append(title)

        sub = Gtk.Label(label="Быстрые действия для настройки системы")
        sub.add_css_class("welcome-sub")
        sub.set_margin_bottom(28)
        main_box.append(sub)

        # Сетка карточек
        grid = Gtk.Grid()
        grid.set_column_spacing(16)
        grid.set_row_spacing(16)
        grid.set_column_homogeneous(True)
        main_box.append(grid)

        cards = [
            ("🪞 Обновить зеркала",
             "Выбрать быстрейшие зеркала\npackman с помощью reflector",
             "pkexec reflector --latest 10 --sort rate "
             "--save /etc/pacman.d/mirrorlist && notify-send "
             "'LynxOS' 'Зеркала обновлены ✅'"),

            ("📦 Обновить систему",
             "Синхронизировать и обновить\nвсе пакеты",
             "pkexec pacman -Syu --noconfirm && notify-send "
             "'LynxOS' 'Система обновлена ✅'"),

            ("🎮 Драйверы GPU",
             "Автоопределить и настроить\nвидеодрайвер",
             "pkexec /usr/local/bin/lynx-gpu-setup && notify-send "
             "'LynxOS' 'Драйверы настроены ✅'"),

            ("🛒 Магазин приложений",
             "Открыть GNOME Software\nдля установки приложений",
             "gnome-software"),

            ("📡 Настройка сети",
             "Открыть менеджер\nсетевых подключений",
             "nm-connection-editor"),

            ("💽 Установить LynxOS",
             "Запустить графический\nустановщик Calamares",
             "pkexec calamares"),

            ("☁️ Настроить rclone",
             "Подключить облачное\nхранилище (Google Drive, etc)",
             "gnome-terminal -- rclone config"),

            ("🔧 yay — AUR Helper",
             "Установить пакеты\nиз AUR репозитория",
             "gnome-terminal -- bash -c 'yay; exec bash'"),
        ]

        for i, (title_txt, desc_txt, cmd) in enumerate(cards):
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            card.add_css_class("card")

            lbl_title = Gtk.Label(label=title_txt)
            lbl_title.set_xalign(0)
            attrs = Pango.AttrList()
            attrs.insert(Pango.attr_weight_new(Pango.Weight.BOLD))
            lbl_title.set_attributes(attrs)
            lbl_title.get_style_context().lookup_color("accent_color")
            card.append(lbl_title)

            lbl_desc = Gtk.Label(label=desc_txt)
            lbl_desc.set_xalign(0)
            lbl_desc.add_css_class("welcome-sub")
            lbl_desc.set_wrap(True)
            card.append(lbl_desc)

            btn = Gtk.Button(label="Запустить")
            btn.add_css_class("action-btn")
            btn.set_halign(Gtk.Align.START)
            btn.set_margin_top(4)
            btn.connect("clicked", self.on_action, cmd, btn)
            card.append(btn)

            col = i % 2
            row = i // 2
            grid.attach(card, col, row, 1, 1)

        # Кнопка "Не показывать снова"
        bottom = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        bottom.set_margin_top(20)
        bottom.set_halign(Gtk.Align.END)

        chk = Gtk.CheckButton(label="Не показывать при запуске")
        chk.connect("toggled", self.on_autostart_toggle)
        bottom.append(chk)
        main_box.append(bottom)

        scroll = Gtk.ScrolledWindow()
        scroll.set_child(main_box)
        scroll.set_vexpand(True)

        win.set_content(scroll)
        win.present()

    def on_action(self, btn, cmd, widget):
        widget.set_label("⏳ Выполняется...")
        widget.set_sensitive(False)

        def done(ok, output):
            widget.set_label("✅ Готово" if ok else "❌ Ошибка")
            widget.set_sensitive(True)

        run_cmd(cmd, done)

    def on_autostart_toggle(self, chk):
        autostart = os.path.expanduser(
            "~/.config/autostart/lynx-welcome.desktop"
        )
        if chk.get_active():
            os.makedirs(os.path.dirname(autostart), exist_ok=True)
            with open(autostart, "w") as f:
                f.write("[Desktop Entry]\nType=Application\n"
                        "Name=LynxOS Welcome\nExec=lynx-welcome\n"
                        "Hidden=true\n")
        else:
            try:
                os.remove(autostart)
            except FileNotFoundError:
                pass


app = LynxWelcome()
import sys
app.run(sys.argv)
WELCOME_EOF
ok "Приложение приветствия lynx-welcome создано"

# Desktop файл для Welcome
cat > airootfs/usr/share/applications/lynx-welcome.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS Welcome
Name[ru]=Приветствие LynxOS
Comment=Экран быстрой настройки LynxOS
Exec=lynx-welcome
Icon=lynxos-logo
Terminal=false
Categories=System;Settings;
EOF

# Автозапуск welcome при первом входе
mkdir -p airootfs/etc/skel/.config/autostart
cat > airootfs/etc/skel/.config/autostart/lynx-welcome.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=LynxOS Welcome
Exec=lynx-welcome
Icon=lynxos-logo
Terminal=false
EOF
ok "Welcome-приложение настроено"

# ─────────────────────────────────────────────
#  СКРИПТ ОБНОВЛЕНИЯ ЗЕРКАЛ
# ─────────────────────────────────────────────
cat > airootfs/usr/local/bin/lynx-mirror-update << 'EOF'
#!/bin/bash
# LynxOS — Обновление зеркал через reflector
set -e
echo "Обновление зеркал pacman..."
if command -v reflector &>/dev/null; then
    reflector --latest 15 --sort rate --protocol https \
              --save /etc/pacman.d/mirrorlist
    echo "✅ Зеркала обновлены"
else
    echo "Установка reflector..."
    pacman -S --noconfirm reflector
    reflector --latest 15 --sort rate --protocol https \
              --save /etc/pacman.d/mirrorlist
fi
EOF
ok "lynx-mirror-update создан"

# ─────────────────────────────────────────────
#  СКРИПТ GPU
# ─────────────────────────────────────────────
cat > airootfs/usr/local/bin/lynx-gpu-setup << 'GPUEOF'
#!/bin/bash
# LynxOS — Автонастройка GPU
LOG="/var/log/lynx-gpu-setup.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== LynxOS GPU Setup $(date) ==="

GPU_INFO=$(lspci | grep -E "VGA|3D|Display" 2>/dev/null || echo "")
echo "Найдено GPU: $GPU_INFO"

ENV_FILE="/etc/environment"

has_amd=false; has_nvidia=false; has_intel=false

echo "$GPU_INFO" | grep -qi "amd\|radeon\|advanced micro" && has_amd=true
echo "$GPU_INFO" | grep -qi "nvidia\|geforce\|quadro\|rtx\|gtx" && has_nvidia=true
echo "$GPU_INFO" | grep -qi "intel" && has_intel=true

if $has_amd; then
    echo "✅ AMD GPU — включаем RADV Vulkan"
    grep -q "RADV" "$ENV_FILE" 2>/dev/null || cat >> "$ENV_FILE" << 'AMD'
VDPAU_DRIVER=radeonsi
LIBVA_DRIVER_NAME=radeonsi
AMD_VULKAN_ICD=RADV
AMD'
fi

if $has_nvidia; then
    echo "✅ NVIDIA GPU — настраиваем проприетарный драйвер"
    grep -q "nvidia" "$ENV_FILE" 2>/dev/null || cat >> "$ENV_FILE" << 'NV'
LIBVA_DRIVER_NAME=nvidia
__GL_SHADER_DISK_CACHE=1
PROTON_ENABLE_NVAPI=1
NV
    echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia-wayland.conf
    mkinitcpio -P 2>/dev/null || true
    systemctl enable nvidia-persistenced 2>/dev/null || true
fi

if $has_intel && ! $has_nvidia; then
    echo "✅ Intel GPU — iHD драйвер"
    grep -q "iHD" "$ENV_FILE" 2>/dev/null || cat >> "$ENV_FILE" << 'INTEL'
LIBVA_DRIVER_NAME=iHD
VDPAU_DRIVER=va_gl
INTEL
fi

if $has_nvidia && ($has_intel || $has_amd); then
    echo "✅ Гибридная графика — настраиваем PRIME Offload"
    cat >> /etc/skel/.bashrc << 'PRIME'

# LynxOS PRIME — запуск на дискретной NVIDIA карте
alias prime='__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia'
alias gameprime='prime gamemoderun'
PRIME
fi

echo "=== GPU Setup завершён ==="
GPUEOF
ok "lynx-gpu-setup создан"

# ─────────────────────────────────────────────
#  FIRSTBOOT СКРИПТ
# ─────────────────────────────────────────────
cat > airootfs/usr/local/bin/lynx-firstboot << 'EOF'
#!/bin/bash
# LynxOS — задачи при первой загрузке ПОСЛЕ установки на диск
LOG="/var/log/lynx-firstboot.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== LynxOS First Boot $(date) ==="

# Поиск Windows для GRUB
echo "Поиск других ОС..."
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

# dconf
dconf update 2>/dev/null || true

# xdg директории
xdg-user-dirs-update 2>/dev/null || true

# Самоудаление
systemctl disable lynx-firstboot.service
echo "=== First Boot завершён ==="
EOF
ok "lynx-firstboot создан"

# ─────────────────────────────────────────────
#  SYSTEMD СЕРВИСЫ
# ─────────────────────────────────────────────
cat > airootfs/etc/systemd/system/lynx-gpu-setup.service << 'EOF'
[Unit]
Description=LynxOS GPU Auto-Setup
After=multi-user.target
ConditionPathExists=!/var/lib/lynx-gpu-configured

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lynx-gpu-setup
ExecStartPost=/bin/touch /var/lib/lynx-gpu-configured
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat > airootfs/etc/systemd/system/lynx-firstboot.service << 'EOF'
[Unit]
Description=LynxOS First Boot Setup
After=network.target
ConditionPathExists=!/var/lib/lynx-firstboot-done

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lynx-firstboot
ExecStartPost=/bin/touch /var/lib/lynx-firstboot-done
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
ok "Systemd сервисы созданы"

# ─────────────────────────────────────────────
#  CALAMARES — settings.conf
# ─────────────────────────────────────────────
cat > airootfs/etc/calamares/settings.conf << 'EOF'
modules-search: [ local, /usr/lib/calamares/modules ]

sequence:
  - show:
    - welcome
    - locale
    - keyboard
    - disk
    - users
    - summary
  - exec:
    - partition
    - mount
    - unpackfs
    - machineid
    - fstab
    - locale
    - keyboard
    - localecfg
    - users
    - displaymanager
    - networkcfg
    - hwclock
    - services-systemd
    - grubcfg
    - bootloader
    - removeuser
    - umount
  - show:
    - finished

branding: lynxos
prompt-install: false
dont-chroot: false
EOF

cat > airootfs/etc/calamares/branding/lynxos/branding.desc << 'EOF'
componentName: lynxos

strings:
  productName: LynxOS
  shortProductName: LynxOS
  version: "1.0"
  shortVersion: "1.0"
  versionedName: LynxOS 1.0
  shortVersionedName: LynxOS 1.0
  bootloaderEntryName: LynxOS
  productUrl: https://lynxos.example.com
  supportUrl: https://lynxos.example.com/support
  releaseNotesUrl: https://lynxos.example.com/release-notes

images:
  productLogo: "lynxos-logo.png"
  productIcon: "lynxos-logo.png"
  productWelcome: "lynxos-logo.png"

style:
  sidebarBackground: "#0d1117"
  sidebarText: "#e6edf3"
  sidebarTextHighlight: "#00bcd4"
  sidebarSelect: "#00bcd4"
EOF
ok "Calamares настроен"

# ─────────────────────────────────────────────
#  GRUB ТЕМА
# ─────────────────────────────────────────────
mkdir -p airootfs/boot/grub/themes/lynxos
cat > airootfs/boot/grub/themes/lynxos/theme.txt << 'EOF'
title-text: ""
desktop-color: "#0d1117"

+ label {
    top = 28%
    left = 50%-180
    width = 360
    height = 56
    text = "LynxOS"
    color = "#00bcd4"
    font = "DejaVu Sans Bold 38"
    align = "center"
}

+ label {
    top = 40%
    left = 50%-200
    width = 400
    height = 22
    text = "Выберите систему для загрузки"
    color = "#4dd0e1"
    font = "DejaVu Sans 13"
    align = "center"
}

+ boot_menu {
    top = 46%
    left = 50%-230
    width = 460
    height = 200
    item_font = "DejaVu Sans 13"
    item_color = "#8b949e"
    selected_item_color = "#00bcd4"
    item_height = 34
    item_padding = 12
    item_spacing = 4
}

+ label {
    top = 83%
    left = 50%-160
    width = 320
    height = 20
    id = "__timeout__"
    text = "Автозагрузка через %d сек."
    color = "#4dd0e1"
    font = "DejaVu Sans 12"
    align = "center"
}

+ label {
    top = 89%
    left = 50%-220
    width = 440
    height = 18
    text = "↑↓ — выбор    Enter — загрузить    e — редактировать"
    color = "#30363d"
    font = "DejaVu Sans 11"
    align = "center"
}
EOF
ok "GRUB тема создана"

# GRUB — включить тему
echo 'GRUB_THEME="/boot/grub/themes/lynxos/theme.txt"' \
    >> airootfs/etc/default/grub

# ─────────────────────────────────────────────
#  customize_airootfs.sh — ГЛАВНЫЙ ХУК
# ─────────────────────────────────────────────
cat > airootfs/root/customize_airootfs.sh << 'HOOK_EOF'
#!/bin/bash
set -e
echo "════════════════════════════════════════"
echo " LynxOS customize_airootfs"
echo "════════════════════════════════════════"

# Используем /var/build вместо /tmp (не занимает tmpfs в RAM)
BDIR="/var/build"
mkdir -p "$BDIR"

# ── Локаль ──────────────────────────────────
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
echo "✅ Локаль: ru_RU.UTF-8"

# ── Live пользователь ───────────────────────
useradd -m -G wheel,audio,video,storage,optical,games,network \
    -s /bin/bash liveuser 2>/dev/null || true
echo "liveuser:liveuser" | chpasswd
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/lynxos-live
echo "✅ liveuser создан (пароль: liveuser)"

# ── Включить сервисы ────────────────────────
systemctl enable gdm
systemctl enable NetworkManager
systemctl enable bluetooth 2>/dev/null || true
systemctl enable lynx-gpu-setup
echo "✅ Сервисы включены"

# ── dconf ───────────────────────────────────
dconf update 2>/dev/null || true

# ── xdg директории ──────────────────────────
xdg-user-dirs-update 2>/dev/null || true

# ── Вспомогательная функция сборки AUR ──────
build_aur() {
    local PKG="$1"
    local URL="$2"
    local USER="_aurbuild_$$"
    local DIR="$BDIR/$PKG"

    useradd -m -s /bin/bash "$USER" 2>/dev/null || true
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/"$USER"

    rm -rf "$DIR"
    sudo -u "$USER" git clone --depth=1 "$URL" "$DIR" 2>/dev/null || {
        echo "⚠️  $PKG: не удалось скачать (нет сети?)"
        userdel -r "$USER" 2>/dev/null || true
        rm -f /etc/sudoers.d/"$USER"
        return 0
    }

    cd "$DIR"
    sudo -u "$USER" makepkg -si --noconfirm 2>/dev/null && \
        echo "✅ $PKG установлен" || \
        echo "⚠️  $PKG: ошибка сборки — пропускаем"

    userdel -r "$USER" 2>/dev/null || true
    rm -f /etc/sudoers.d/"$USER"
    rm -rf "$DIR"
    cd /
}

# ── AUR пакеты ──────────────────────────────
build_aur "adw-gtk3"               "https://aur.archlinux.org/adw-gtk3.git"
build_aur "localsend-bin"          "https://aur.archlinux.org/localsend-bin.git"
build_aur "visual-studio-code-bin" "https://aur.archlinux.org/visual-studio-code-bin.git"
build_aur "yay"                    "https://aur.archlinux.org/yay.git"

# ── Права файлов ─────────────────────────────
chmod +x /usr/local/bin/lynx-gpu-setup
chmod +x /usr/local/bin/lynx-firstboot
chmod +x /usr/local/bin/lynx-welcome
chmod +x /usr/local/bin/lynx-mirror-update
chmod +x /etc/skel/Desktop/install-lynxos.desktop 2>/dev/null || true

# ── GRUB начальный конфиг ───────────────────
grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true

# ── Очистка /var/build и кэша pacman ────────
rm -rf "$BDIR"
pacman -Sc --noconfirm 2>/dev/null || true

echo ""
echo "════════════════════════════════════════"
echo " customize_airootfs ЗАВЕРШЁН ✅"
echo "════════════════════════════════════════"
HOOK_EOF

chmod +x airootfs/root/customize_airootfs.sh
ok "customize_airootfs.sh создан"

# ─────────────────────────────────────────────
#  КОНВЕРТАЦИЯ SVG ЛОГОТИПА В PNG
# ─────────────────────────────────────────────
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SVG_SRC="$SCRIPT_DIR/lynxos-logo.svg"

if [ -f "$SVG_SRC" ] && command -v inkscape &>/dev/null; then
    info "Конвертация логотипа SVG → PNG..."
    for SIZE in 16 32 48 128 256; do
        inkscape "$SVG_SRC" \
            --export-filename="$BUILDDIR/lynxos-logo-${SIZE}.png" \
            --export-width=$SIZE --export-height=$SIZE 2>/dev/null
        cp "$BUILDDIR/lynxos-logo-${SIZE}.png" \
            "$BASE/airootfs/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/lynxos-logo.png"
    done
    cp "$BUILDDIR/lynxos-logo-256.png" \
        "$BASE/airootfs/usr/share/pixmaps/lynxos-logo.png"
    cp "$BUILDDIR/lynxos-logo-256.png" \
        "$BASE/airootfs/etc/calamares/branding/lynxos/lynxos-logo.png"
    ok "Логотип PNG создан во всех размерах"
else
    warn "Скопируй PNG логотип вручную в:"
    warn "  airootfs/etc/calamares/branding/lynxos/lynxos-logo.png"
    warn "  airootfs/usr/share/pixmaps/lynxos-logo.png"
fi

# ─────────────────────────────────────────────
#  ИТОГ
# ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     LynxOS — структура готова! ✅            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo " Для сборки ISO запусти:"
echo -e "  ${CYAN}bash build-lynxos.sh${NC}"
echo ""
echo " Нужно свободного места: ~35 GB"
echo " Примерное время:        40–60 мин"
echo ""

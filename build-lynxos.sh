#!/bin/bash
# ============================================================
#  LynxOS — Скрипт СБОРКИ ISO (v2)
#  Запускать после setup-lynxos.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'
YELLOW='\033[1;33m'; NC='\033[0m'

BASE="$HOME/lynxos"
WORK="/tmp/lynxos-work"
OUT="$HOME/lynxos-output"

echo -e "${CYAN}"
cat << 'BANNER'
  ██╗  ██╗   ██╗███╗  ██╗██╗  ██╗ ██████╗ ███████╗
  ██║  ╚██╗ ██╔╝████╗ ██║╚██╗██╔╝██╔═══██╗██╔════╝
  ██║   ╚████╔╝ ██╔██╗██║ ╚███╔╝ ██║   ██║███████╗
  ██║    ╚██╔╝  ██║╚████║ ██╔██╗ ██║   ██║╚════██║
  ███████╗██║   ██║ ╚███║██╔╝╚██╗╚██████╔╝███████║
  ╚══════╝╚═╝   ╚═╝  ╚══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
BANNER
echo -e "${NC}"
echo -e "  ${GREEN}Сборка LynxOS 1.0${NC}"
echo ""

# ── Проверки ────────────────────────────────────
[ ! -d "$BASE" ] && \
    echo -e "${RED}Сначала запусти setup-lynxos.sh!${NC}" && exit 1

command -v mkarchiso &>/dev/null || \
    sudo pacman -S --noconfirm archiso

# Проверка свободного места (нужно ~30 GB)
FREE_GB=$(df / --output=avail -BG | tail -1 | tr -d 'G ')
if [ "$FREE_GB" -lt 25 ]; then
    echo -e "${RED}Недостаточно места! Нужно ~30 GB, доступно: ${FREE_GB} GB${NC}"
    exit 1
fi
echo -e "${GREEN}Свободное место: ${FREE_GB} GB ✅${NC}"

# ── Очистка предыдущей сборки ──────────────────
if [ -d "$WORK" ]; then
    echo "Очистка временных файлов..."
    sudo rm -rf "$WORK"
fi

mkdir -p "$OUT"

# ── Сборка ────────────────────────────────────
echo ""
echo -e "${CYAN}Начало сборки... Лог: $OUT/build.log${NC}"
echo ""

sudo mkarchiso -v \
    -w "$WORK" \
    -o "$OUT" \
    "$BASE" 2>&1 | tee "$OUT/build.log"

# ── Результат ─────────────────────────────────
ISO=$(ls "$OUT"/lynxos-*.iso 2>/dev/null | head -1)

if [ -f "$ISO" ]; then
    SIZE=$(du -sh "$ISO" | cut -f1)
    MD5=$(md5sum "$ISO" | cut -d' ' -f1)
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           СБОРКА УСПЕШНА! 🎉                  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ISO:    ${CYAN}$ISO${NC}"
    echo -e "  Размер: ${CYAN}$SIZE${NC}"
    echo -e "  MD5:    ${CYAN}$MD5${NC}"
    echo ""
    echo -e "${YELLOW}  Запись на USB:${NC}"
    echo -e "  ${CYAN}sudo dd if=$ISO of=/dev/sdX bs=4M status=progress && sync${NC}"
    echo ""
    echo -e "${YELLOW}  Тест в QEMU (без флешки):${NC}"
    echo -e "  ${CYAN}sudo pacman -S --needed qemu-full${NC}"
    echo -e "  ${CYAN}qemu-system-x86_64 -m 4G -cdrom $ISO -boot d -enable-kvm -vga virtio${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}Сборка не удалась. Проверь лог: $OUT/build.log${NC}"
    echo ""
    echo "Последние строки лога:"
    tail -30 "$OUT/build.log"
    exit 1
fi

#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  LynxOS — Инструмент для работы с ISO
#  Запись на USB, тестирование, создание bootable флешек
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

info() { echo -e "${CYAN}[ISO Tool]${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; exit 1; }

# ═══════════════════════════════════════════════════════════════
#  1. Получить список USB устройств
# ═══════════════════════════════════════════════════════════════
list_usb_devices() {
    info "Сканирование USB устройств..."
    
    lsblk -nd -o NAME,SIZE,TYPE,MODEL | grep -v "^loop\|^sr" | while read -r name size type model; do
        if [ "$type" = "disk" ]; then
            info "USB: /dev/$name ($size) — $model"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════
#  2. Записать ISO на USB (dd)
# ═══════════════════════════════════════════════════════════════
write_iso_to_usb() {
    local iso_file="$1"
    local device="$2"
    
    [ ! -f "$iso_file" ] && err "ISO файл не найден: $iso_file"
    [ ! -b "$device" ] && err "USB устройство не найдено: $device"
    
    # Проверка безопасности
    if echo "$device" | grep -qE "^/dev/sd[a-z]$|^/dev/nvme[0-9]n[0-9]$"; then
        local size=$(lsblk -nd -o SIZE "$device" 2>/dev/null || echo "unknown")
        warn "⚠️  ВНИМАНИЕ! Это перезапишет все данные на $device ($size)"
        read -p "Вы уверены? Введите 'yes' для подтверждения: " confirm
        [ "$confirm" != "yes" ] && info "Операция отменена" && return 1
    else
        err "Неправильный путь к устройству: $device"
        return 1
    fi
    
    # Размонтировать все разделы
    info "Размонтирование разделов..."
    for partition in "${device}"*; do
        if mountpoint -q "$partition" 2>/dev/null; then
            sudo umount "$partition" 2>/dev/null || true
        fi
    done
    
    # Запись
    info "Запись ISO на USB (это может занять время)..."
    sudo dd if="$iso_file" of="$device" bs=4M status=progress conv=fsync || {
        err "Ошибка при записи ISO"
        return 1
    }
    
    ok "ISO успешно записан на $device"
    info "Извлечение USB флешки..."
    sudo eject "$device" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════
#  3. Записать ISO с использованием Etcher (если установлен)
# ═══════════════════════════════════════════════════════════════
write_iso_with_etcher() {
    local iso_file="$1"
    local device="$2"
    
    if ! command -v balena-etcher-electron &>/dev/null && \
       ! command -v balenaEtcher &>/dev/null; then
        warn "Balena Etcher не установлен"
        return 1
    fi
    
    info "Запись с использованием Balena Etcher..."
    balena-etcher-electron --unmount auto --drive "$device" "$iso_file" || \
    balenaEtcher --unmount auto --drive "$device" "$iso_file" || \
        err "Ошибка Etcher"
}

# ═══════════════════════════════════════════════════════════════
#  4. Проверить целостность ISO (MD5/SHA256)
# ═══════════════════════════════════════════════════════════════
verify_iso() {
    local iso_file="$1"
    local checksum_file="$2"
    
    [ ! -f "$iso_file" ] && err "ISO файл не найден: $iso_file"
    [ ! -f "$checksum_file" ] && err "Файл контрольной суммы не найден: $checksum_file"
    
    info "Проверка целостности ISO..."
    
    if grep -q "sha256" "$checksum_file"; then
        sha256sum -c "$checksum_file" && ok "Контрольная сумма верна!" || \
            err "Контрольная сумма не совпадает!"
    elif grep -q "md5" "$checksum_file" || [ "$(wc -c < "$checksum_file")" -lt 50 ]; then
        md5sum -c "$checksum_file" && ok "Контрольная сумма верна!" || \
            err "Контрольная сумма не совпадает!"
    else
        err "Неизвестный формат контрольной суммы"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
#  5. Тестировать ISO в QEMU
# ═══════════════════════════════════════════════════════════════
test_iso_qemu() {
    local iso_file="$1"
    local memory="${2:-4}"
    
    [ ! -f "$iso_file" ] && err "ISO файл не найден: $iso_file"
    
    if ! command -v qemu-system-x86_64 &>/dev/null; then
        warn "QEMU не установлен. Установка..."
        sudo pacman -S --noconfirm qemu-full >/dev/null 2>&1 || \
            err "Не удалось установить QEMU"
    fi
    
    info "Запуск ISO в QEMU (${memory}G памяти)..."
    info "Советы: Ctrl+Alt+G для захвата/отпуска мыши"
    
    qemu-system-x86_64 \
        -m ${memory}G \
        -smp 4 \
        -cdrom "$iso_file" \
        -boot d \
        -enable-kvm \
        -vga virtio \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0 || true
}

# ═══════════════════════════════════════════════════════════════
#  6. Создать bootable флешку с Ventoy
# ═══════════════════════════════════════════════════════════════
setup_ventoy() {
    local device="$1"
    
    if ! command -v ventoy &>/dev/null; then
        warn "Ventoy не установлен. Скачивание..."
        local ventoy_url="https://github.com/ventoy/Ventoy/releases/download/v1.0.96/ventoy-1.0.96-linux.tar.gz"
        curl -L "$ventoy_url" | tar -xz -C /tmp || \
            err "Не удалось скачать Ventoy"
    fi
    
    info "Установка Ventoy на $device..."
    sudo /tmp/ventoy-1.0.96/Ventoy2Disk.sh -i "$device" || \
        err "Ошибка установки Ventoy"
    
    ok "Ventoy установлен на $device"
    info "Теперь скопируйте ISO файл в первый раздел"
}

# ═══════════════════════════════════════════════════════════════
#  7. Информация об ISO
# ═══════════════════════════════════════════════════════════════
iso_info() {
    local iso_file="$1"
    
    [ ! -f "$iso_file" ] && err "ISO файл не найден: $iso_file"
    
    info "Информация об ISO: $iso_file"
    echo ""
    echo "  Размер:           $(ls -lh "$iso_file" | awk '{print $5}')"
    echo "  MD5:              $(md5sum "$iso_file" | awk '{print $1}')"
    echo "  SHA256:           $(sha256sum "$iso_file" | awk '{print $1}')"
    echo "  Тип файла:        $(file "$iso_file" | cut -d: -f2-)"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
#  ГЛАВНОЕ МЕНЮ
# ═══════════════════════════════════════════════════════════════

show_menu() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}    LynxOS — Инструмент ISO${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    echo "  1) Список USB устройств"
    echo "  2) Записать ISO на USB (dd)"
    echo "  3) Записать ISO с Etcher (если установлен)"
    echo "  4) Проверить целостность ISO"
    echo "  5) Тестировать ISO в QEMU"
    echo "  6) Установить Ventoy на USB"
    echo "  7) Информация об ISO"
    echo "  8) Выход"
    echo ""
}

main() {
    case "${1:-interactive}" in
        list-usb)
            list_usb_devices
            ;;
        write-dd)
            [ -z "${2:-}" ] && err "Укажите путь к ISO"
            [ -z "${3:-}" ] && err "Укажите USB устройство (например, /dev/sdb)"
            write_iso_to_usb "$2" "$3"
            ;;
        write-etcher)
            [ -z "${2:-}" ] && err "Укажите путь к ISO"
            [ -z "${3:-}" ] && err "Укажите USB устройство (например, /dev/sdb)"
            write_iso_with_etcher "$2" "$3"
            ;;
        verify)
            [ -z "${2:-}" ] && err "Укажите путь к ISO"
            [ -z "${3:-}" ] && err "Укажите файл контрольной суммы"
            verify_iso "$2" "$3"
            ;;
        test-qemu)
            [ -z "${2:-}" ] && err "Укажите путь к ISO"
            test_iso_qemu "$2" "${3:-4}"
            ;;
        ventoy)
            [ -z "${2:-}" ] && err "Укажите USB устройство (например, /dev/sdb)"
            setup_ventoy "$2"
            ;;
        info)
            [ -z "${2:-}" ] && err "Укажите путь к ISO"
            iso_info "$2"
            ;;
        *)
            # Интерактивный режим
            while true; do
                show_menu
                read -p "Выберите опцию (1-8): " choice
                echo ""
                
                case "$choice" in
                    1) list_usb_devices ;;
                    2) 
                        read -p "Путь к ISO файлу: " iso
                        read -p "USB устройство (например, /dev/sdb): " dev
                        write_iso_to_usb "$iso" "$dev"
                        ;;
                    3)
                        read -p "Путь к ISO файлу: " iso
                        read -p "USB устройство (например, /dev/sdb): " dev
                        write_iso_with_etcher "$iso" "$dev"
                        ;;
                    4)
                        read -p "Путь к ISO файлу: " iso
                        read -p "Путь к файлу контрольной суммы: " sum
                        verify_iso "$iso" "$sum"
                        ;;
                    5)
                        read -p "Путь к ISO файлу: " iso
                        read -p "Объем памяти в ГБ (по умолчанию 4): " mem
                        test_iso_qemu "$iso" "${mem:-4}"
                        ;;
                    6)
                        read -p "USB устройство (например, /dev/sdb): " dev
                        setup_ventoy "$dev"
                        ;;
                    7)
                        read -p "Путь к ISO файлу: " iso
                        iso_info "$iso"
                        ;;
                    8) exit 0 ;;
                    *) warn "Неверный выбор" ;;
                esac
                
                read -p "Нажмите Enter для продолжения..."
                clear
            done
            ;;
    esac
}

main "$@"

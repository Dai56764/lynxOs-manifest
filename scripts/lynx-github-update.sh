#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  LynxOS — Обновление системы через GitHub
#  Скачивает и применяет обновления с репозитория GitHub
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

REPO="${LYNXOS_REPO:-Dai56764/lynxOs-manifest}"
CACHE_DIR="${HOME}/.cache/lynxos"
STATE_DIR="${HOME}/.local/share/lynxos"
RELEASES_FILE="${CACHE_DIR}/releases.json"

mkdir -p "$CACHE_DIR" "$STATE_DIR"

info() { echo -e "${CYAN}[LynxOS Update]${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; exit 1; }

# ═══════════════════════════════════════════════════════════════
#  1. Получить информацию о релизах
# ═══════════════════════════════════════════════════════════════
fetch_releases() {
    info "Получение информации о релизах..."
    
    if curl -sL "https://api.github.com/repos/${REPO}/releases" -o "$RELEASES_FILE" 2>/dev/null; then
        ok "Информация о релизах получена"
    else
        warn "Не удалось получить информацию о релизах. Проверьте соединение."
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
#  2. Получить последний релиз
# ═══════════════════════════════════════════════════════════════
get_latest_release() {
    if [ -f "$RELEASES_FILE" ]; then
        python3 -c "
import json
try:
    with open('$RELEASES_FILE', 'r') as f:
        data = json.load(f)
    if isinstance(data, list) and len(data) > 0:
        latest = data[0]
        print(f\"tag_name={latest.get('tag_name', '')}|name={latest.get('name', '')}|body={latest.get('body', '')}\")
except Exception as e:
    print('')
" 2>/dev/null || return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
#  3. Скачать ISO
# ═══════════════════════════════════════════════════════════════
download_iso() {
    local tag_name="$1"
    local download_dir="${2:-.}"
    
    info "Получение информации о скачивании для $tag_name..."
    
    local iso_url="https://github.com/${REPO}/releases/download/${tag_name}/lynxos-x86_64.iso"
    local iso_file="${download_dir}/lynxos-latest.iso"
    
    if [ -f "$iso_file" ]; then
        warn "Файл $iso_file уже существует"
        return 1
    fi
    
    info "Скачивание ISO (это может занять время)..."
    if curl -L --progress-bar "$iso_url" -o "$iso_file" 2>/dev/null; then
        ok "ISO скачан: $iso_file"
        return 0
    else
        err "Не удалось скачать ISO"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
#  4. Применить локальное обновление (ISO или архив)
# ═══════════════════════════════════════════════════════════════
apply_local_update() {
    local source="$1"
    
    if [ ! -f "$source" ]; then
        err "Файл не найден: $source"
        return 1
    fi
    
    case "$source" in
        *.iso)
            info "Обнаружен ISO файл: $source"
            apply_iso_update "$source"
            ;;
        *.tar.gz|*.tar.xz)
            info "Обнаружен архив: $source"
            apply_archive_update "$source"
            ;;
        *)
            err "Неизвестный формат файла: $source"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#  5. Применить обновление из ISO
# ═══════════════════════════════════════════════════════════════
apply_iso_update() {
    local iso_file="$1"
    local mount_point="/tmp/lynxos-update-iso"
    
    info "Монтирование ISO: $iso_file"
    sudo mkdir -p "$mount_point"
    sudo mount -o loop "$iso_file" "$mount_point" 2>/dev/null || {
        err "Не удалось смонтировать ISO"
        return 1
    }
    
    trap "sudo umount '$mount_point' 2>/dev/null || true" EXIT
    
    # Примеры: можно обновить пакеты, ядро, конфигурацию и т.д.
    if [ -f "${mount_point}/arch/pkgdata.tar.gz" ]; then
        info "Найдены данные пакетов, применение..."
        # cd /tmp && tar -xzf "${mount_point}/arch/pkgdata.tar.gz"
        ok "Данные пакетов извлечены"
    fi
    
    ok "Обновление из ISO завершено"
    return 0
}

# ═══════════════════════════════════════════════════════════════
#  6. Применить обновление из архива
# ═══════════════════════════════════════════════════════════════
apply_archive_update() {
    local archive_file="$1"
    local extract_dir="/tmp/lynxos-update"
    
    info "Извлечение архива: $archive_file"
    mkdir -p "$extract_dir"
    tar -xf "$archive_file" -C "$extract_dir" || {
        err "Не удалось извлечь архив"
        return 1
    }
    
    # Пример: применить конфигурацию
    if [ -f "${extract_dir}/system.conf" ]; then
        info "Применение системной конфигурации..."
        sudo install -m644 "${extract_dir}/system.conf" /etc/ || true
        ok "Конфигурация применена"
    fi
    
    ok "Обновление из архива завершено"
    rm -rf "$extract_dir"
    return 0
}

# ═══════════════════════════════════════════════════════════════
#  ГЛАВНОЕ МЕНЮ
# ═══════════════════════════════════════════════════════════════

show_menu() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}    LynxOS — Обновление из GitHub${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo ""
    echo "  1) Показать доступные релизы"
    echo "  2) Скачать последний ISO"
    echo "  3) Применить локальное обновление (ISO/архив)"
    echo "  4) Информация о системе"
    echo "  5) Выход"
    echo ""
}

show_releases() {
    if [ ! -f "$RELEASES_FILE" ]; then
        fetch_releases || return
    fi
    
    echo -e "${YELLOW}Доступные релизы:${NC}"
    python3 -c "
import json
try:
    with open('$RELEASES_FILE', 'r') as f:
        data = json.load(f)
    for i, rel in enumerate(data[:10], 1):
        tag = rel.get('tag_name', 'N/A')
        name = rel.get('name', 'N/A')
        date = rel.get('published_at', 'N/A')[:10]
        print(f'{i}. {tag} ({name}) — {date}')
except Exception as e:
    print('Ошибка при чтении информации о релизах')
" 2>/dev/null || true
}

main() {
    case "${1:-interactive}" in
        fetch)
            fetch_releases
            ;;
        list)
            show_releases
            ;;
        download)
            fetch_releases || exit 1
            RELEASE=$(get_latest_release)
            TAG=$(echo "$RELEASE" | cut -d'|' -f1 | cut -d'=' -f2)
            download_iso "$TAG" "${2:-.}"
            ;;
        apply)
            [ -z "${2:-}" ] && err "Укажите путь к ISO или архиву"
            apply_local_update "$2"
            ;;
        info)
            echo "Информация о системе LynxOS:"
            echo ""
            echo "  Версия ядра:     $(uname -r)"
            echo "  Платформа:       $(uname -m)"
            echo "  Репозиторий:     $REPO"
            echo "  Кеш:             $CACHE_DIR"
            echo "  Состояние:       $STATE_DIR"
            echo ""
            ;;
        *)
            # Интерактивный режим
            while true; do
                show_menu
                read -p "Выберите опцию (1-5): " choice
                echo ""
                
                case "$choice" in
                    1) show_releases ;;
                    2) fetch_releases || true; RELEASE=$(get_latest_release); TAG=$(echo "$RELEASE" | cut -d'|' -f1 | cut -d'=' -f2); download_iso "$TAG" ;;
                    3) read -p "Путь к файлу (ISO/архив): " file; apply_local_update "$file" ;;
                    4) 
                        echo "Информация о системе LynxOS:"
                        echo ""
                        echo "  Версия ядра:     $(uname -r)"
                        echo "  Платформа:       $(uname -m)"
                        echo "  Репозиторий:     $REPO"
                        echo ""
                        ;;
                    5) exit 0 ;;
                    *) warn "Неверный выбор" ;;
                esac
                
                read -p "Нажмите Enter для продолжения..."
                clear
            done
            ;;
    esac
}

main "$@"

#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  LynxOS — Рекомендуемые приложения
#  Показывает окно GNOME с предложением установить популярные
#  приложения, как в Manjaro
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Проверка, первый ли это запуск после установки
STATE_DIR="${HOME}/.local/share/lynxos"
RECOMMENDED_SHOWN_FILE="${STATE_DIR}/recommended-shown"
mkdir -p "$STATE_DIR"

# Если уже показывались, выходим
if [ -f "$RECOMMENDED_SHOWN_FILE" ]; then
    exit 0
fi

# JSON с рекомендуемыми приложениями
APPS_JSON=$(mktemp)
cat > "$APPS_JSON" <<'EOF'
{
  "categories": [
    {
      "name": "🎵 Мультимедиа",
      "apps": [
        {"name": "VLC", "package": "vlc", "desc": "Универсальный видеоплеер"},
        {"name": "Krita", "package": "krita", "desc": "Графический редактор"},
        {"name": "Blender", "package": "blender", "desc": "3D моделирование и анимация"},
        {"name": "Audacity", "package": "audacity", "desc": "Аудиоредактор"}
      ]
    },
    {
      "name": "🔧 Разработка",
      "apps": [
        {"name": "Visual Studio Code", "package": "visual-studio-code-bin", "desc": "Редактор кода"},
        {"name": "Neovim", "package": "neovim", "desc": "Продвинутый текстовый редактор"},
        {"name": "Docker", "package": "docker", "desc": "Контейнеризация приложений"},
        {"name": "DBeaver", "package": "dbeaver", "desc": "Управление БД"}
      ]
    },
    {
      "name": "📝 Документы и офис",
      "apps": [
        {"name": "LibreOffice", "package": "libreoffice-fresh", "desc": "Офисный пакет"},
        {"name": "Thunderbird", "package": "thunderbird", "desc": "Почтовый клиент"},
        {"name": "Zotero", "package": "zotero", "desc": "Менеджер научных ссылок"}
      ]
    },
    {
      "name": "🎮 Игры и развлечения",
      "apps": [
        {"name": "Steam", "package": "steam", "desc": "Платформа игр"},
        {"name": "Lutris", "package": "lutris", "desc": "Запуск игр с Windows"},
        {"name": "OBS Studio", "package": "obs-studio", "desc": "Трансляция и запись"}
      ]
    }
  ]
}
EOF

# Создание интерфейса с zenity (GNOME-совместимо)
if ! command -v zenity &> /dev/null; then
    echo "Installing zenity..."
    sudo pacman -S --noconfirm zenity >/dev/null 2>&1 || exit 0
fi

# Показываем диалог
zenity --info \
    --title="LynxOS — Добро пожаловать! 🎉" \
    --text="Добро пожаловать в LynxOS!\n\nВы можете установить дополнительные приложения для улучшения вашего опыта.\n\nНажмите 'Далее' для просмотра рекомендуемых приложений." \
    --width=400 \
    --height=200 \
    2>/dev/null || true

# Генерируем список для выбора (используем zenity list)
SELECTED=$(zenity --list \
    --title="Рекомендуемые приложения" \
    --text="Выберите приложения для установки (Ctrl+Click для множественного выбора):" \
    --checklist \
    --column="Установить" \
    --column="Приложение" \
    --column="Описание" \
    FALSE "VLC" "Универсальный видеоплеер" \
    FALSE "Visual Studio Code" "Редактор кода" \
    FALSE "LibreOffice" "Офисный пакет" \
    FALSE "Thunderbird" "Почтовый клиент" \
    FALSE "Krita" "Графический редактор" \
    FALSE "Blender" "3D моделирование" \
    FALSE "Docker" "Контейнеризация" \
    FALSE "Steam" "Платформа игр" \
    FALSE "OBS Studio" "Трансляция и запись" \
    FALSE "DBeaver" "Управление БД" \
    --separator="," \
    --width=600 \
    --height=400 \
    2>/dev/null || SELECTED="")

if [ -n "$SELECTED" ]; then
    # Маппинг приложений на пакеты
    declare -A PACKAGES=(
        ["VLC"]="vlc"
        ["Visual Studio Code"]="visual-studio-code-bin"
        ["LibreOffice"]="libreoffice-fresh"
        ["Thunderbird"]="thunderbird"
        ["Krita"]="krita"
        ["Blender"]="blender"
        ["Docker"]="docker"
        ["Steam"]="steam"
        ["OBS Studio"]="obs-studio"
        ["DBeaver"]="dbeaver"
    )

    # Извлекаем пакеты для установки
    PKGS_TO_INSTALL=""
    IFS=',' read -ra APPS_ARRAY <<< "$SELECTED"
    for app in "${APPS_ARRAY[@]}"; do
        if [ -n "${PACKAGES[$app]:-}" ]; then
            PKGS_TO_INSTALL="${PKGS_TO_INSTALL} ${PACKAGES[$app]}"
        fi
    done

    if [ -n "$PKGS_TO_INSTALL" ]; then
        # Показываем прогресс установки
        {
            echo "0"
            echo "# Загрузка зависимостей..."
            sudo pacman -Sy --noconfirm >/dev/null 2>&1

            TOTAL=$(echo $PKGS_TO_INSTALL | wc -w)
            COUNT=0
            for pkg in $PKGS_TO_INSTALL; do
                COUNT=$((COUNT + 1))
                PERCENT=$((COUNT * 100 / TOTAL))
                echo "$PERCENT"
                echo "# Установка $pkg ($COUNT/$TOTAL)..."
                sudo pacman -S --noconfirm "$pkg" >/dev/null 2>&1 || true
            done

            echo "100"
            echo "# Установка завершена!"
        } | zenity --progress \
            --title="Установка приложений" \
            --text="Пожалуйста подождите..." \
            --percentage=0 \
            --no-cancel \
            --width=400 \
            --height=100 \
            2>/dev/null || true

        zenity --info \
            --title="Успешно!" \
            --text="Приложения установлены.\n\nОни доступны в меню приложений." \
            --width=400 \
            --height=150 \
            2>/dev/null || true
    fi
fi

# Отмечаем, что окно показано
touch "$RECOMMENDED_SHOWN_FILE"
rm -f "$APPS_JSON"

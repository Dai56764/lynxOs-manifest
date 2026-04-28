# 🚀 LynxOS 1.0 — Начало работы

## Что было сделано

Ваш проект LynxOS полностью обновлен с полным набором возможностей:

### ✅ Основные компоненты
- ✓ Полный список пакетов (140+ пакетов)
- ✓ Linux-zen ядро с заголовками
- ✓ GNOME рабочий стол с расширениями
- ✓ Calamares графический установщик
- ✓ PipeWire аудиосистема

### ✅ Поддержка оборудования
- ✓ Драйверы Intel GPU (mesa, libva-intel-driver, intel-gpu-tools)
- ✓ Драйверы NVIDIA (nvidia, cuda-libs, nvidia-settings)
- ✓ Драйверы AMD (xf86-video-amdgpu, amdvlk, mesa)
- ✓ Switcheroo-control для переключения видеокарт
- ✓ Поддержка CPU scaling и ACPI

### ✅ Инструменты обновления
- ✓ **lynx-system-update** — локальное обновление через pacman
- ✓ **lynx-github-update** — обновления через GitHub релизы
- ✓ **lynx-iso-tool** — управление ISO, запись на USB, QEMU
- ✓ **lynx-recommended-apps** — окно с рекомендуемыми приложениями

### ✅ Разработка
- ✓ GCC, Clang, LLVM компиляторы
- ✓ Python 3 с pip
- ✓ Git система контроля версий
- ✓ CMake и Make
- ✓ base-devel с полным набором инструментов

### ✅ Документация
- ✓ README.md — полное описание
- ✓ User-Guide.md — руководство для пользователей
- ✓ Developer-Guide.md — руководство для разработчиков
- ✓ GitHub Actions workflow для автосборки

---

## 📋 Структура файлов

```
lynxos-manifest/
├── setup-lynxos.sh                    # Инициализация профиля
├── build-lynxos.sh                    # Сборка ISO
├── scripts/
│   ├── lynx-recommended-apps.sh       # Рекомендуемые приложения
│   ├── lynx-github-update.sh          # Обновления через GitHub
│   └── lynx-iso-tool.sh               # Инструмент ISO
├── calamares/
│   ├── settings.conf                  # Основная конфигурация
│   ├── users.conf                     # Конфигурация пользователя
│   ├── partition.conf                 # Разметка дисков
│   └── displaymanager.conf            # Менеджер сеансов
├── desktop-entries/                   # .desktop файлы
│   ├── lynx-recommended-apps.desktop
│   ├── lynx-github-update.desktop
│   └── lynx-iso-tool.desktop
├── docs/
│   ├── wiki/
│   │   ├── Home.md
│   │   ├── Build-on-GitHub.md
│   │   ├── Project-Structure.md
│   │   ├── User-Guide.md              # ✅ НОВОЕ
│   │   └── Developer-Guide.md         # ✅ НОВОЕ
│   └── QUICKSTART.md                  # Этот файл
├── .github/
│   └── workflows/
│       └── build-iso.yml              # ✅ ОБНОВЛЕНО
└── README.md                          # ✅ ПОЛНОСТЬЮ ПЕРЕПИСАНО
```

---

## 🎯 Первые шаги

### 1️⃣ На машине с Arch Linux

```bash
# Клонируем репозиторий
git clone https://github.com/Dai56764/lynxOs-manifest.git
cd lynxOs-manifest

# Инициализируем профиль (создает ~/lynxos)
bash setup-lynxos.sh

# Собираем ISO (займет 30-60 минут)
bash build-lynxos.sh

# ISO будет в ~/lynxos-output/lynxos-x86_64.iso
ls -lh ~/lynxos-output/
```

### 2️⃣ Запись на USB флешку

```bash
# Показать список устройств
lsblk

# Записать на USB (замените /dev/sdb на ваше устройство!)
sudo dd if=~/lynxos-output/lynxos-x86_64.iso of=/dev/sdb bs=4M status=progress && sync

# Или использовать инструмент (после установки)
lynx-iso-tool write-dd ~/lynxos-output/lynxos-x86_64.iso /dev/sdb
```

### 3️⃣ Установка

1. Загрузитесь с USB флешки
2. Выберите "Установить LynxOS" на рабочем столе
3. Следуйте инструкциям Calamares
4. После установки система автоматически запустит окно с рекомендуемыми приложениями

### 4️⃣ После установки

```bash
# Система готова к работе!
# Все инструменты доступны через Applications меню или терминал

# Примеры:
lynx-system-update          # Обновить систему
lynx-github-update          # Проверить обновления GitHub
lynx-iso-tool               # Управлять ISO
lynx-recommended-apps       # Просмотр рекомендуемых приложений
```

---

## 📚 Документация

| Файл | Назначение |
|------|-----------|
| [README.md](../README.md) | Основное описание проекта |
| [User-Guide.md](wiki/User-Guide.md) | Полное руководство пользователя |
| [Developer-Guide.md](wiki/Developer-Guide.md) | Руководство для разработчиков |
| [Build-on-GitHub.md](wiki/Build-on-GitHub.md) | Автосборка через GitHub Actions |
| [Project-Structure.md](wiki/Project-Structure.md) | Структура проекта |

---

## 🛠️ Основные инструменты

### lynx-system-update
Локальное обновление пакетов и проверка новых релизов:

```bash
lynx-system-update
# Или через Applications > LynxOS Update
```

### lynx-github-update
Загрузка обновлений через GitHub:

```bash
lynx-github-update          # Интерактивный режим
lynx-github-update list     # Список релизов
lynx-github-update download # Скачать последний ISO
lynx-github-update apply FILE  # Применить обновление
```

### lynx-iso-tool
Работа с ISO образами:

```bash
lynx-iso-tool              # Интерактивный режим
lynx-iso-tool list-usb     # Список USB устройств
lynx-iso-tool write-dd ISO /dev/sdX  # Запись на USB
lynx-iso-tool test-qemu ISO          # Тестировать в QEMU
lynx-iso-tool info ISO     # Информация об ISO
```

### lynx-recommended-apps
Окно с рекомендуемыми приложениями:

```bash
lynx-recommended-apps
# Или через Applications > Recommended Apps
```

---

## 🎮 Включенные приложения и категории

### 🎵 Мультимедиа
- VLC, Krita, Blender, Audacity

### 🔧 Разработка  
- Visual Studio Code, Neovim, Docker, DBeaver

### 📝 Офис
- LibreOffice, Thunderbird, Zotero

### 🎮 Игры
- Steam, Lutris, OBS Studio

**Все эти приложения можно установить автоматически при первом запуске!**

---

## 🔧 Кастомизация

### Добавление пакетов

Отредактируйте `setup-lynxos.sh`, найдите `packages.x86_64` и добавьте новые пакеты:

```bash
nano setup-lynxos.sh
# Найти packages.x86_64
# Добавить ваши пакеты
# Сохранить и пересобрать
```

### Добавление собственных скриптов

1. Создайте скрипт в `scripts/my-tool.sh`
2. Добавьте в `setup-lynxos.sh`:

```bash
cat > airootfs/usr/local/bin/my-tool << 'MYTOOL'
#!/bin/bash
# ваш код
MYTOOL
chmod +x airootfs/usr/local/bin/my-tool
```

3. Пересоберите ISO

---

## 🚀 GitHub Actions (Автосборка)

ISO автоматически собирается при:
- Push в `main` или `master` ветку → создается GitHub Release
- Pull Request → сборка в Artifacts
- Ручной запуск (Actions → Build LynxOS ISO → Run workflow)

Все релизы с ISO доступны на странице [Releases](https://github.com/Dai56764/lynxOs-manifest/releases)

---

## 🆘 Решение проблем

### Проблема: "Недостаточно места"
```bash
# Нужно ~50 GB (30 GB для сборки + резерв)
df -h
# Если недостаточно, удалите ненужные файлы
sudo pacman -Sc  # Очистить кеш
```

### Проблема: "Не могу монтировать ISO"
```bash
# Убедитесь что loop модуль загружен
sudo modprobe loop

# Проверьте ISO целостность
sha256sum lynxos-x86_64.iso
```

### Проблема: "USB флешка не загружается"
```bash
# 1. Убедитесь что записали правильное устройство
lsblk

# 2. Проверьте BIOS (Boot order, Secure Boot если нужно)

# 3. Попробуйте другой USB порт

# 4. Используйте Balena Etcher вместо dd
```

### Проблема: "Система медленная после установки"
```bash
# Обновите систему
lynx-system-update

# Очистите кеш
sudo pacman -Sc

# Проверьте процессы
btop
```

---

## 📞 Получение помощи

1. **Проверьте документацию**:
   - [User-Guide.md](wiki/User-Guide.md) для пользователей
   - [Developer-Guide.md](wiki/Developer-Guide.md) для разработчиков

2. **Создайте Issue** на GitHub:
   - https://github.com/Dai56764/lynxOs-manifest/issues

3. **Включите полезную информацию**:
   - Версия системы: `uname -a`
   - Ошибка: полный текст из журналов
   - Логи сборки если актуально

---

## 📈 Что дальше?

### Для пользователей
1. ✅ Установить LynxOS с ISO
2. ✅ Выбрать рекомендуемые приложения
3. ✅ Использовать lynx-system-update для обновления
4. ✅ Переставлять через новые ISO при выпуске

### Для разработчиков
1. ✅ Изучить Developer-Guide.md
2. ✅ Fork репозитория
3. ✅ Добавить свои возможности
4. ✅ Создать Pull Request

---

## 📊 Статистика проекта

- **Пакетов в ISO**: 140+
- **Размер ISO**: ~2-3 GB (зависит от конфигурации)
- **Время сборки**: 30-60 минут (зависит от интернета и диска)
- **Минимум места**: 50 GB
- **ОС для сборки**: Arch Linux и совместимые
- **Платформа**: x86_64 (64-bit)

---

## 🎉 Готово!

Проект LynxOS полностью готов к использованию!

```
✅ Собрать ISO:
   bash setup-lynxos.sh && bash build-lynxos.sh

✅ Записать на USB:
   sudo dd if=~/lynxos-output/lynxos-x86_64.iso of=/dev/sdX bs=4M status=progress

✅ Установить:
   Загрузитесь с USB и следуйте инструкциям

✅ Использовать:
   lynx-system-update, lynx-github-update, lynx-iso-tool и другие инструменты
```

---

**Версия**: 1.0  
**Дата**: 2026-04-28  
**Автор**: LynxOS Team  
**Лицензия**: GPL v2+ (Arch Linux, GNOME, Calamares)

Спасибо за использование LynxOS! 🚀

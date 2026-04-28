# LynxOS — Кастомный Arch Linux дистрибутив

**LynxOS** — это полнофункциональный дистрибутив Linux на основе Arch Linux с предустановленной средой GNOME, графическим установщиком Calamares, расширенной поддержкой оборудования и инструментами для обновления через GitHub.

## 🎯 Основные возможности

### 🖥️ Окружение и интерфейс
- **GNOME Desktop** — современное и удобное окружение рабочего стола
- **Calamares** — графический установщик для удобной установки ОС
- **GDM** — менеджер сеансов GNOME
- Предустановленные расширения GNOME Shell

### 🔧 Ядро и оборудование
- **Linux-zen** — оптимизированное ядро для ПК
- Поддержка **всех видеокарт**:
  - Intel (mesa, libva-intel-driver, intel-media-driver)
  - NVIDIA (nvidia, cuda-libs, nvidia-settings)
  - AMD (xf86-video-amdgpu, amdvlk, libva-mesa-driver)
- **Switcheroo-control** — переключение между дискретной и встроенной видеокартой
- Универсальные драйверы и поддержка ACPI

### 📦 Разработка
- **Компиляторы**: GCC, Clang, LLVM
- **Python 3** с pip
- **Git** для версионного контроля
- **CMake** и **Make** для сборки
- Все необходимые инструменты разработки в `base-devel`

### 🔄 Обновления и управление
- **lynx-system-update** — обновление пакетов и проверка новых релизов
- **lynx-github-update** — загрузка и применение обновлений через GitHub
- **lynx-iso-tool** — работа с ISO файлами (запись на USB, тестирование в QEMU)
- **lynx-mirror-update** — автоматический выбор быстрых зеркал pacman

### 💬 Приложения первого запуска
- **Рекомендуемые приложения** — окно GNOME со списком популярных приложений (VLC, VSCode, LibreOffice и т.д.)
- Автоматическая установка выбранных приложений
- Поддержка пакетов AUR

### 🎵 Мультимедиа
- **PipeWire** — современный аудиосервер
- Поддержка ALSA, PulseAudio, JACK
- **FFmpeg** для обработки видео
- GStreamer с полным набором плагинов
- Поддержка Vulkan и OpenGL

### 🌐 Сеть и система
- **NetworkManager** — управление сетевыми подключениями
- **Bluetooth** (bluez, blueman)
- Разметка дисков: **parted, gptfdisk, efibootmgr**
- Поддержка NTFS, ExFAT, Btrfs
- Firewall: базовые инструменты

### 📚 Шрифты и интернационализация
- Качественные шрифты (Noto, Liberation, JetBrains Mono, Fira Code)
- Поддержка emoji и CJK (китайский, японский, корейский)
- Локализация на русский и другие языки

## 🚀 Быстрый старт

### На локальной машине (Arch/Manjaro/EndeavourOS)

```bash
# 1. Клонируем репозиторий
git clone https://github.com/Dai56764/lynxOs-manifest.git
cd lynxOs-manifest

# 2. Инициализируем профиль ArchISO
chmod +x setup-lynxos.sh build-lynxos.sh
bash setup-lynxos.sh

# 3. Собираем ISO (нужно ~30 GB свободного места)
bash build-lynxos.sh

# 4. ISO находится в ~/lynxos-output/lynxos-x86_64.iso
```

### Запись на USB флешку

```bash
# Показать список USB устройств
lsblk

# Записать ISO на USB (замените /dev/sdX на ваше устройство)
sudo dd if=~/lynxos-output/lynxos-x86_64.iso of=/dev/sdX bs=4M status=progress && sync
```

### Тестирование в QEMU

```bash
# Установить QEMU
sudo pacman -S qemu-full

# Запустить ISO в виртуальной машине (4GB RAM)
qemu-system-x86_64 -m 4G -cdrom ~/lynxos-output/lynxos-x86_64.iso -boot d -enable-kvm
```

## 🛠️ Встроенные инструменты

### lynx-system-update
Обновление пакетов и проверка новых релизов:

```bash
lynx-system-update
# или через GNOME Applications menu
```

### lynx-github-update
Загрузка и применение обновлений через GitHub:

```bash
# Интерактивный режим
lynx-github-update

# Команды:
lynx-github-update fetch              # Получить инфо о релизах
lynx-github-update list               # Список релизов
lynx-github-update download           # Скачать последний ISO
lynx-github-update apply /path/to/iso # Применить ISO обновление
```

### lynx-iso-tool
Работа с ISO файлами:

```bash
# Интерактивный режим
lynx-iso-tool

# Команды:
lynx-iso-tool list-usb                  # Список USB устройств
lynx-iso-tool write-dd iso /dev/sdX     # Записать на USB
lynx-iso-tool test-qemu iso             # Тестировать в QEMU
lynx-iso-tool verify iso checksum.txt   # Проверить контрольную сумму
lynx-iso-tool ventoy /dev/sdX           # Установить Ventoy на USB
```

### lynx-recommended-apps
Рекомендуемые приложения запускаются автоматически после первой загрузки. Можно запустить вручную:

```bash
lynx-recommended-apps
```

## 📁 Структура репозитория

```
lynxos-manifest/
├── setup-lynxos.sh              # Создание профиля ArchISO
├── build-lynxos.sh              # Сборка ISO
├── scripts/
│   ├── lynx-recommended-apps.sh # Рекомендуемые приложения
│   ├── lynx-github-update.sh    # Обновления через GitHub
│   └── lynx-iso-tool.sh         # Инструмент для работы с ISO
├── calamares/
│   ├── settings.conf            # Основная конфигурация
│   ├── users.conf               # Конфигурация пользователя
│   ├── partition.conf           # Разметка дисков
│   └── displaymanager.conf      # Менеджер сеансов
├── docs/
│   ├── wiki/
│   │   ├── Home.md              # Главная страница
│   │   ├── Build-on-GitHub.md   # Сборка через GitHub Actions
│   │   └── Project-Structure.md # Структура проекта
├── .github/
│   └── workflows/
│       └── build-iso.yml        # GitHub Actions workflow
└── README.md                     # Этот файл
```

## 🔨 Развертывание через GitHub Actions

Проект поддерживает автоматическую сборку ISO через GitHub Actions.

**Действия**:
1. Push в `main` или `master` ветку создает релиз с ISO
2. Любой Push создает артефакты в Actions
3. Manual workflow dispatch для разработки

[Подробнее в Build-on-GitHub.md](docs/wiki/Build-on-GitHub.md)

## 🎯 Обновления и циклы выпуска

- **Обновление пакетов**: `pacman -Syu` (rolling release, как в Arch)
- **Новые релизы LynxOS**: скачивается свежий ISO через `lynx-github-update`
- **Текущая система НЕ обновляется на месте** — используйте свежий ISO для переустановки при необходимости

## 🔒 Безопасность

- Стандартные пакеты Arch Linux
- Поддержка Secure Boot
- Группа `wheel` может использовать `sudo` без пароля в Live окружении
- NTFS-3G для безопасной работы с диском Windows

## 📝 Лицензия и авторство

**LynxOS** основан на [Arch Linux](https://archlinux.org/) и использует [ArchISO](https://archlinux.org/archiso/).

- Arch Linux — [GNU GPL v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
- GNOME — [GNU GPL v2+](https://gitlab.gnome.org/GNOME)
- Calamares — [GNU GPL v3](https://github.com/calamares/calamares)
- PipeWire — [MIT](https://github.com/PipeWire/pipewire)

## 🆘 Помощь и поддержка

- 📖 [Документация](docs/wiki/)
- 🐛 [Issues](https://github.com/Dai56764/lynxOs-manifest/issues)
- 💬 [Discussions](https://github.com/Dai56764/lynxOs-manifest/discussions)

## 🎁 Дополнительно

### Рекомендуемые приложения (автоустановка)

**Мультимедиа**:
- VLC — видеоплеер
- Krita — графический редактор
- Blender — 3D моделирование
- Audacity — аудиоредактор

**Разработка**:
- Visual Studio Code — редактор кода
- Docker — контейнеризация
- DBeaver — управление БД

**Офис**:
- LibreOffice — офисный пакет
- Thunderbird — почта

**Игры**:
- Steam — платформа игр
- Lutris — запуск Windows игр
- OBS Studio — трансляция и запись

### Дополнительные команды

```bash
# Просмотр информации о системе
fastfetch

# Мониторинг ресурсов
btop

# Информация об оборудовании
hwinfo

# Информация о видеокарте
glxinfo (для Intel/Nvidia)
vulkaninfo (для AMD)
```

---

**Версия**: 1.0  
**Последнее обновление**: 2026-04-28  
**Статус**: Активно разрабатывается

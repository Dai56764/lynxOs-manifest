# LynxOS v2 — Исправленная сборка

## Что исправлено
- `SigLevel = Never` в pacman.conf (больше не зависает на выборе)
- Убран chaotic-aur из pacman.conf (устанавливается в хуке)
- `syslinux` добавлен в пакеты
- `mesa-vdpau` заменён на `libva-mesa-driver`
- `adw-gtk3`, `visual-studio-code-bin`, `localsend-bin`, `yay` — собираются через makepkg в хуке
- `qt5-webengine` убран (calamares не требует)
- `linux-zen` корректно из репозитория extra

## Новое в v2
- btop, htop, fastfetch (с конфигом)
- Полные мультимедийные кодеки (gst-plugins-*, ffmpeg, libva)
- LocalSend — обмен файлами между устройствами
- rclone — работа с облаком
- Качественные шрифты (JetBrains Mono, Noto Fonts, Fira Code)
- Welcome-приложение (Python/GTK4) с кнопками быстрых действий
- yay — AUR-помощник
- GRUB тема в стиле LynxOS

## Файлы
| Файл | Назначение |
|---|---|
| `setup-lynxos.sh` | Создаёт структуру проекта |
| `build-lynxos.sh` | Собирает ISO |
| `lynxos-logo.svg` | Логотип рысь |
| `grub-theme.txt` | Тема GRUB |

## Запуск
```bash
# На Arch Linux / Manjaro / EndeavourOS:
chmod +x setup-lynxos.sh build-lynxos.sh
bash setup-lynxos.sh
bash build-lynxos.sh
```

## Требования
- Arch Linux / Manjaro / EndeavourOS (хост)
- RAM: 8 GB
- Место: ~35 GB свободно
- Интернет: обязателен

## Учётные данные Live
- Пользователь: `liveuser`
- Пароль: `liveuser`
- sudo без пароля

## Тест без флешки
```bash
sudo pacman -S qemu-full
qemu-system-x86_64 -m 4G -cdrom ~/lynxos-output/lynxos-*.iso -boot d -enable-kvm -vga virtio
```

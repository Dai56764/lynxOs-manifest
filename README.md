
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

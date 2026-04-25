# Project Structure

## Root files

- `setup-lynxos.sh`: creates the ArchISO working profile under `$HOME/lynxos`
- `build-lynxos.sh`: runs `mkarchiso` and writes the ISO to `$HOME/lynxos-output`
- `lynxos-logo.svg`: branding asset
- `grub-theme.txt`: GRUB theme source/reference

## Build output

During local or CI builds, the scripts generate:

- `$HOME/lynxos`
- `$HOME/build/lynxos-work`
- `$HOME/lynxos-output`

## CI behavior

In GitHub Actions, `HOME` is redirected to a workspace-local folder so the generated profile and ISO files remain accessible to artifact upload steps.

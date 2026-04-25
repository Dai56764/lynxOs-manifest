# LynxOS Wiki

LynxOS is an Arch-based custom distribution project with:

- `setup-lynxos.sh` for generating the ArchISO profile
- `build-lynxos.sh` for building the final ISO
- GitHub Actions automation for repeatable cloud builds

## Quick links

- [Build on GitHub](./Build-on-GitHub.md)
- [Project structure](./Project-Structure.md)

## Current defaults

- Desktop: GNOME
- Installer: Calamares
- Kernel: `linux-zen`
- Live user: `liveuser`
- Time zone in the generated image: `Europe/Moscow`

## Goal

The repository is designed so you can:

1. keep the distro source in GitHub,
2. build release ISO images through Actions,
3. publish artifacts and releases from the default branch,
4. expand this folder into a full GitHub Wiki later.

# LynxOS

LynxOS is a custom Arch-based Linux distribution project that generates an ISO image with GNOME, archinstall, Timeshift, Google Chrome support, multimedia codecs and custom branding.

## Repository layout

- `setup-lynxos.sh` creates the ArchISO profile under `$HOME/lynxos`
- `build-lynxos.sh` builds the final ISO into `$HOME/lynxos-output`
- `.github/workflows/build-iso.yml` builds the project on GitHub Actions
- `docs/wiki/` contains the starter wiki content for the project

## Local build

Run the project on an Arch-based host:

```bash
chmod +x setup-lynxos.sh build-lynxos.sh
bash setup-lynxos.sh
bash build-lynxos.sh
```

## GitHub build

The GitHub Actions workflow:

- runs on `push`, `pull_request` and `workflow_dispatch`
- builds inside an Arch Linux Docker container
- uploads the ISO and checksum files as artifacts
- creates a GitHub release on pushes to `main` or `master`

See [docs/wiki/Build-on-GitHub.md](docs/wiki/Build-on-GitHub.md) for details.

## Update model

- system packages are updated through `pacman -Syu`
- the generated image sets `ParallelDownloads = 10` in `pacman.conf`
- `lynx-system-update` refreshes mirrors, upgrades the system and checks whether a newer LynxOS release exists
- a fresh ISO is intended for reinstall or recovery, not for in-place replacement of the running system

## Important note

The current scripts are written for Arch-based environments. Running the build outside Arch, or on a runner without enough disk space, will still fail even with a correct workflow.

ARM64 is not part of the current build pipeline. This repository builds an `x86_64` ArchISO; a real `aarch64` release would need a separate Arch Linux ARM build flow rather than a small workflow tweak.

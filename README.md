# LynxOS

LynxOS is a custom Arch-based Linux distribution project that generates an ISO image with GNOME, archinstall, gaming packages, multimedia codecs and custom branding.

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

## Important note

The current scripts are written for Arch-based environments. Running the build outside Arch, or on a runner without enough disk space, will still fail even with a correct workflow.

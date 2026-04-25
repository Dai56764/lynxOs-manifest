# Build on GitHub

## Workflow

The repository includes `.github/workflows/build-iso.yml`.

It builds the ISO inside an `archlinux:latest` Docker container on a GitHub-hosted Ubuntu runner. This is more reliable than trying to run the whole job as a container with ad-hoc setup steps.

## What the workflow does

1. Checks out the repository.
2. Frees disk space on the runner.
3. Starts a privileged Arch Linux container.
4. Installs the packages needed for `archiso`.
5. Runs `setup-lynxos.sh`.
6. Runs `build-lynxos.sh`.
7. Uploads the ISO and checksum files as artifacts.
8. Creates a GitHub release on pushes to `main` or `master`.

## Manual run

Use `workflow_dispatch` to start a build manually.

The workflow also supports `enable_aur=true` if you want to try building the optional AUR packages during the CI build. Keep it disabled by default until the base ISO build is stable.

## Notes

- GitHub-hosted runners have limited disk space and runtime, so the ISO should stay as lean as possible.
- AUR packages make CI slower and less predictable.
- Release assets are generated automatically only on direct pushes to the default branch.

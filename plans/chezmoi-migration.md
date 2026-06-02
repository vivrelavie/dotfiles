# Chezmoi Migration Plan

Date: 2026-06-02

## Objective

Migrate this dotfiles repository from GNU Stow package directories to a real chezmoi source tree without losing live configuration, generated theme state, or DMS plugin state.

The migration should preserve the current working setup first, then make the repository portable enough for fresh-machine restore.

## Current State

The repo is currently stow-shaped:

```text
fish/.config/fish/config.fish
kitty/.config/kitty/kitty.conf
matugen/.config/matugen/config.toml
matugen/.config/matugen/templates/*
niri/.config/niri/config.kdl
fastfetch/.config/fastfetch/logos/cat.txt
DankMaterialShell/.config/DankMaterialShell/*
```

The README already describes chezmoi, but the repository has not been converted yet. Keep that mismatch open until the source tree actually uses chezmoi.

Generated/runtime files are now ignored and should stay out of Git:

```text
local-artifacts/
DankMaterialShell/.config/DankMaterialShell/firefox.css
DankMaterialShell/.config/DankMaterialShell/zen.css
DankMaterialShell/.config/DankMaterialShell/.firstlaunch
DankMaterialShell/.config/DankMaterialShell/.changelog-*
DankMaterialShell/.config/DankMaterialShell/plugins/.repos/
DankMaterialShell/.config/DankMaterialShell/plugins/*
fastfetch/.config/fastfetch/config.jsonc
fish/.config/fish/fish_variables
kitty/.config/kitty/dank-tabs.conf
kitty/.config/kitty/dank-theme.conf
niri/.config/niri/dms/
```

DMS plugin policy is currently: track `.meta` files only, let DMS recreate cloned plugin repos and install symlinks.

Chezmoi is not currently installed on this machine:

```text
chezmoi: command not found
```

## Target Chezmoi Layout

Convert the tracked stow paths into chezmoi source paths:

```text
fish/.config/fish/config.fish
-> dot_config/fish/config.fish

kitty/.config/kitty/kitty.conf
-> dot_config/kitty/kitty.conf

matugen/.config/matugen/config.toml
-> dot_config/matugen/config.toml

matugen/.config/matugen/templates/*
-> dot_config/matugen/templates/*

niri/.config/niri/config.kdl
-> dot_config/niri/config.kdl

fastfetch/.config/fastfetch/logos/cat.txt
-> dot_config/fastfetch/logos/cat.txt

DankMaterialShell/.config/DankMaterialShell/settings.json
-> dot_config/DankMaterialShell/settings.json

DankMaterialShell/.config/DankMaterialShell/plugin_settings.json
-> dot_config/DankMaterialShell/plugin_settings.json

DankMaterialShell/.config/DankMaterialShell/plugins/*.meta
-> dot_config/DankMaterialShell/plugins/*.meta

DankMaterialShell/.config/DankMaterialShell/scripts/update-niri-focus.sh
-> dot_config/DankMaterialShell/scripts/executable_update-niri-focus.sh
```

Use chezmoi attribute prefixes for executable files instead of relying only on Git executable bits.

## Generated File Policy

Keep source templates tracked:

```text
dot_config/matugen/templates/fastfetch.jsonc
dot_config/matugen/templates/niri-focus.kdl
dot_config/matugen/templates/starship.toml
```

Keep rendered outputs outside the chezmoi source tree:

```text
~/.cache/matugen/fastfetch.jsonc
~/.cache/matugen/starship.toml
~/.cache/DankMaterialShell/niri-focus.kdl
```

Keep DMS-generated app integration files untracked:

```text
~/.config/DankMaterialShell/firefox.css
~/.config/DankMaterialShell/zen.css
~/.config/kitty/dank-tabs.conf
~/.config/kitty/dank-theme.conf
~/.config/niri/dms/*.kdl
```

If any app cannot start without a generated include, document the bootstrap order or add a checked-in fallback stub during the migration branch.

## Migration Phases

### 1. Prepare and Protect

- Install or otherwise make `chezmoi` available.
- Run `chezmoi doctor` before changing repository layout.
- Create a fresh backup archive of `/home/stef/dotfiles`.
- Confirm `git status --short --ignored` only shows ignored generated files.
- Create a migration branch, for example `migration/chezmoi-source`.
- Do not use `chezmoi apply` until `chezmoi diff` has been reviewed.

### 2. Convert Paths

- Move tracked package files into `dot_config/...` paths with `git mv`.
- Rename `update-niri-focus.sh` to `executable_update-niri-focus.sh`.
- Remove empty stow package directories after the moves.
- Keep `plans/` and `local-artifacts/` as repo-support paths, not target dotfiles.

### 3. Add Chezmoi Metadata

- Add `.chezmoiignore` for local planning/session artifacts and generated paths if needed.
- Consider `.chezmoi.toml.tmpl` only if machine-specific data becomes necessary.
- Avoid templates until there is a real variable to substitute.
- Keep `~` and XDG path usage in app configs where the app supports it.

### 4. Test Without Applying

Run:

```sh
chezmoi doctor
chezmoi diff
chezmoi apply --dry-run --verbose
```

Confirm the diff does not remove live generated DMS plugin repos, generated theme files, or Fish universal state.

### 5. Controlled Apply

- Apply only after the dry run is clean.
- Re-check that `~/.config/niri/config.kdl` is managed by chezmoi and not replaced by DMS scripts.
- Run the patched DMS Niri focus helper and confirm the Niri config remains managed.

### 6. Regenerate Runtime Theme Files

Run a known-good matugen render:

```sh
matugen color hex '#b99ab6' -c ~/.config/matugen/config.toml
```

Validate:

```sh
fastfetch --config ~/.cache/matugen/fastfetch.jsonc --pipe true --logo none
env STARSHIP_CONFIG=~/.cache/matugen/starship.toml starship explain
niri validate -c ~/.config/niri/config.kdl
```

If DMS owns theme generation, also trigger the normal DMS wallpaper/theme workflow and confirm the generated include files exist.

### 7. README and Bootstrap

Only after the converted tree works:

- Rewrite `README.md` so the install instructions match the actual chezmoi source tree.
- Add any bootstrap scripts intentionally, such as `run_once_before_install_packages.sh.tmpl`.
- Keep package installation separate from config migration unless the package list is reviewed.

### 8. Final Cutover

- Commit the converted source tree.
- Push the migration branch.
- On a clean test clone, run `chezmoi init --source <repo-path>` and inspect `chezmoi diff`.
- After validation, merge to `main`.

## Rollback

If chezmoi apply creates a bad state:

```sh
tar -tzf /home/stef/dotfiles-backup-*.tar.gz | head
```

Then restore only the affected config files from the latest backup archive, not the whole home directory. Prefer targeted restore for:

```text
~/.config/fish/config.fish
~/.config/kitty/kitty.conf
~/.config/matugen/
~/.config/niri/config.kdl
~/.config/DankMaterialShell/
```

## Session Handover

Next session should start by reading:

```text
plans/chezmoi-migration.md
local-artifacts/SESSION_HANDOVER.md
```

Do not start the path conversion until the current repo state is clean and backed up again.

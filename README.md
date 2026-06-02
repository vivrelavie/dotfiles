# My CachyOS Dotfiles

Personal Arch/CachyOS configuration for Niri, DankMaterialShell, Kitty, Fish,
Matugen, and Fastfetch. This repository is a chezmoi source tree.

Chezmoi source paths live in this repository under `dot_config/...`. When
applied, they become real files under `~/.config/...`.

## Fresh Install

Install chezmoi and apply this repository:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply vivrelavie/dotfiles
```

This repository does not currently include a package bootstrap script. Install
the required packages separately before expecting the full desktop session to
work.

## Local Apply

When working from this checkout:

```sh
chezmoi --source ~/dotfiles diff
chezmoi --source ~/dotfiles apply
```

To make this checkout the default source directory on this machine:

```sh
chezmoi init --source ~/dotfiles
```

## Source Layout

Tracked chezmoi targets:

```text
dot_config/DankMaterialShell/
dot_config/fastfetch/
dot_config/kitty/
dot_config/matugen/
dot_config/niri/
dot_config/private_fish/
```

`dot_config/private_fish/` maps to `~/.config/fish/` and keeps that directory
private.

## Generated State

The repository tracks source templates and durable DMS plugin metadata only.
Generated/runtime files stay out of Git.

Tracked:

```text
dot_config/matugen/templates/*.jsonc
dot_config/matugen/templates/*.kdl
dot_config/matugen/templates/*.toml
dot_config/DankMaterialShell/plugins/*.meta
```

Generated locally:

```text
~/.cache/matugen/fastfetch.jsonc
~/.cache/matugen/starship.toml
~/.cache/DankMaterialShell/niri-focus.kdl
~/.config/DankMaterialShell/firefox.css
~/.config/DankMaterialShell/zen.css
~/.config/kitty/dank-tabs.conf
~/.config/kitty/dank-theme.conf
~/.config/niri/dms/*.kdl
```

## Daily Workflow

Edit a managed file:

```sh
chezmoi --source ~/dotfiles edit --apply ~/.config/niri/config.kdl
```

Inspect and apply changes from this checkout:

```sh
chezmoi --source ~/dotfiles diff
chezmoi --source ~/dotfiles apply
```

Commit source changes:

```sh
git status
git add .
git commit -m "Update dotfiles"
git push
```

## Validation

Regenerate theme outputs:

```sh
matugen color hex '#b99ab6' -c ~/.config/matugen/config.toml
```

Validate generated configs:

```sh
fastfetch --config ~/.cache/matugen/fastfetch.jsonc --pipe true --logo none
env STARSHIP_CONFIG=~/.cache/matugen/starship.toml starship explain
niri validate -c ~/.config/niri/config.kdl
```

## TODO

- Fix behavior for overview when changing wallpaper.

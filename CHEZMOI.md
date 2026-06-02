# Chezmoi Details

This file keeps the source/target mapping details.

## What Chezmoi Restores

Managed targets:

```text
~/.config/DankMaterialShell/
~/.config/fastfetch/
~/.config/fish/
~/.config/kitty/
~/.config/matugen/
~/.config/niri/
~/install-cachyos.sh
```

Source paths:

```text
dot_config/DankMaterialShell/
dot_config/fastfetch/
dot_config/kitty/
dot_config/matugen/
dot_config/niri/
dot_config/private_fish/
executable_install-cachyos.sh
```

`dot_config/private_fish/` maps to `~/.config/fish/` and keeps that target
directory private.

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

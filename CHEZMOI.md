# Chezmoi Details

This file keeps the source/target mapping details.

## What Chezmoi Restores

Managed targets:

```text
~/.config/fastfetch/
~/.config/fish/
~/.config/kitty/
~/.config/niri/
~/install.sh
```

DMS profile only:

```text
~/.config/DankMaterialShell/
~/.config/matugen/
```

Source paths:

```text
.chezmoi.toml.tmpl
dot_config/DankMaterialShell/
dot_config/fastfetch/
dot_config/kitty/kitty.conf.tmpl
dot_config/matugen/
dot_config/niri/config.kdl.tmpl
dot_config/private_fish/
executable_install.sh
```

`dot_config/private_fish/` maps to `~/.config/fish/` and keeps that target
directory private.

## Machine Profile

`.chezmoi.toml.tmpl` prompts once per machine for `desktop_shell`.

Supported values:

```text
dms
noctalia-v4
noctalia-v5
none
```

The Niri and Kitty configs are templates. They keep the shared config intact
while switching shell-specific autostart commands, IPC binds, generated include
files, and DMS-only target directories.

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

DMS-generated locally:

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

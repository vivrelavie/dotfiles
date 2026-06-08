# Arch/CachyOS Dotfiles

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Niri](https://img.shields.io/badge/Niri-WM-ff69b4?style=for-the-badge)
![Managed by Chezmoi](https://img.shields.io/badge/chezmoi-000000?style=for-the-badge&logo=chezmoi&logoColor=white)

My personal Arch/CachyOS configuration reinstall repo for Niri with a selectable desktop shell profile. This repository is managed with [chezmoi](https://www.chezmoi.io/).

## Fresh Install

Use these steps after installing Arch or CachyOS and booting into the new user
account. Networking must work, and the user must be able to run `sudo`.

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init vivrelavie
bash ~/.local/share/chezmoi/executable_install.sh
```

This uses chezmoi's GitHub shorthand and initializes `vivrelavie/dotfiles`.
During `chezmoi init`, choose the desktop shell profile for the machine:
`dms`, `noctalia-v4`, `noctalia-v5`, or `none`.

The installer shows a review menu before installing packages. It can also show
the pending chezmoi diff and run `chezmoi apply --interactive`, so file writes
and overwrites are confirmed before package installation starts.

For an already-applied checkout, run:

```sh
~/install.sh
```

After the installer finishes, reboot or log out and back in:

```sh
sudo reboot
```

If Tailscale was installed, authenticate it after reboot:

```sh
sudo tailscale up
```

## Install Script

The install script is tracked as `executable_install.sh`. Chezmoi applies it as `~/install.sh` with executable permissions.

It will:

```text
- ask which package/action groups should run before installation
- optionally show chezmoi file changes and run chezmoi apply --interactive
- install yay if it is missing
- install desktop packages, fonts, apps, Fish, Fastfetch, Yazi, Neovim, GitHub CLI, OpenSSH, and Tailscale
- install LazyVim starter config if ~/.config/nvim does not exist
- apply the Adw-GTK3 dark theme when gsettings is available
- remove Firefox if it is installed
- enable and start sshd.service and tailscaled.service when available
- install the selected desktop shell: DankMaterialShell, Noctalia v4, Noctalia v5, or none
- remove stock Niri helper apps replaced by DMS or this repo when the DMS profile is selected
```

Non-interactive examples:

```sh
~/install.sh --desktop-shell dms --yes
~/install.sh --desktop-shell noctalia-v5 --yes
```

## Software Stack

| Category       | Application              | Package                   | Description                                  |
| :------------- | :----------------------- | :------------------------ | :------------------------------------------- |
| Window Manager | Niri                     | `niri`                    | Scrollable tiling Wayland compositor.        |
| Shell UI       | DankMaterialShell        | official installer        | Default shell profile.                       |
| Shell UI       | Noctalia v4              | `noctalia-shell`          | Stable Quickshell-based alternative profile. |
| Shell UI       | Noctalia v5              | `noctalia-git`            | Alpha native Noctalia alternative profile.   |
| Shell          | Fish                     | `fish`                    | Friendly interactive shell.                  |
| Terminal       | Kitty                    | `kitty`                   | GPU-accelerated terminal emulator.           |
| Terminal UI    | Yazi                     | `yazi`                    | Terminal file manager.                       |
| System Info    | Fastfetch                | `fastfetch`               | System information summary for the terminal. |
| Browser        | Zen Browser              | `zen-browser-bin`         | Firefox-based browser.                       |
| Editor         | VSCodium                 | `vscodium-bin`            | Open-source VS Code build.                   |
| Editor         | Neovim                   | `neovim`                  | Terminal editor with LazyVim starter config. |
| CLI            | GitHub CLI               | `github-cli`              | GitHub commands from the terminal.           |
| Chat           | Vesktop                  | `vesktop-bin`             | Desktop client for Discord.                  |
| Music          | Spotify                  | `spotify`                 | Music streaming desktop client.              |
| Recording      | OBS Studio               | `obs-studio`              | Screen recording and streaming tool.         |
| File Sharing   | LocalSend                | `localsend-bin`           | Local network file transfer.                 |
| Services       | OpenSSH                  | `openssh`                 | SSH client and server package.               |
| Services       | Tailscale                | `tailscale`               | Mesh VPN for private device access.          |
| Maintenance    | BleachBit                | `bleachbit`               | Cleanup tool for cache and temporary files.  |
| Fonts          | JetBrains Mono           | `ttf-jetbrains-mono`      | Base terminal and editor font.               |
| Fonts          | JetBrains Mono Nerd Font | `ttf-jetbrains-mono-nerd` | Patched font for terminal icons.             |
| Theme          | Adw GTK Theme            | `adw-gtk-theme`           | GTK3 theme matching Libadwaita style.        |

## Theming And Appearance

The bootstrap script applies `adw-gtk3-dark` and sets the GNOME color scheme to
`prefer-dark` when `gsettings` is available.

The Kitty config uses `JetBrains Mono Nerd Font`. If terminal icons render as
empty boxes, confirm the terminal font is set to `JetBrainsMono Nerd Font` or
`JetBrains Mono Nerd Font`.

For the DMS profile, if colors or generated theme files look stale, change the
wallpaper from DankMaterialShell and let it regenerate the theme outputs.

More chezmoi mapping details live in [CHEZMOI.md](CHEZMOI.md).

## Manual Steps After Install

1. Log in to Zen Browser, Vesktop, Spotify, VSCodium Sync, GitHub CLI, and Tailscale.
2. Run `sudo tailscale up` if Tailscale has not been authenticated yet.
3. Change the wallpaper in the selected desktop shell if generated colors or theme files look stale.
4. Open the selected desktop shell settings if it uses default layout or theme values after first launch.
5. Install hardware-specific drivers, optional cursor themes, and any machine-specific secrets separately.

## Troubleshooting

### The installer failed on a package

Re-run the script after fixing the failing package or install the package
manually with yay:

```sh
yay -S package_name
~/install.sh
```

### Chezmoi did not use this checkout as the source

Open the active chezmoi source directory:

```sh
chezmoi cd
```

## Fresh Install Checks

Validate configs and services:

```sh
niri validate -c ~/.config/niri/config.kdl
systemctl status sshd.service
systemctl status tailscaled.service
chezmoi status
```

## Daily Workflow

Edit a managed file:

Format:

```sh
chezmoi edit --apply <target-file>
```

Example:

```sh
chezmoi edit --apply ~/.config/niri/config.kdl
```

Inspect and apply changes from this checkout:

```sh
chezmoi diff
chezmoi apply
```

Track a GUI/config change:

```sh
chezmoi add ~/.config/DankMaterialShell
```

Commit source changes:

```sh
chezmoi cd
git status
git add .
git commit -m "Update dotfiles"
git push
```

## TODO

- Fix behavior for overview when changing wallpaper.

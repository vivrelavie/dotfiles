# Arch/CachyOS Dotfiles

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Niri](https://img.shields.io/badge/Niri-WM-ff69b4?style=for-the-badge)
![Managed by Chezmoi](https://img.shields.io/badge/chezmoi-000000?style=for-the-badge&logo=chezmoi&logoColor=white)

My personal Arch/CachyOS configuration reinstall repo for Niri + DankMaterialShell. This repository is managed with [chezmoi](https://www.chezmoi.io/).

## Fresh Install

Use these steps after installing Arch or CachyOS and booting into the new user
account. Networking must work, and the user must be able to run `sudo`.

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply vivrelavie
~/install.sh
```

This uses chezmoi's GitHub shorthand and applies `vivrelavie/dotfiles`. It
expects the repo to be public, or GitHub authentication to already be available.

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
- install yay if it is missing
- install desktop packages, fonts, apps, Fish, Fastfetch, Yazi, Neovim, GitHub CLI, OpenSSH, and Tailscale
- install LazyVim starter config if ~/.config/nvim does not exist
- apply the Adw-GTK3 dark theme when gsettings is available
- remove Firefox if it is installed
- enable and start sshd.service and tailscaled.service when available
- install DankMaterialShell using its official installer if dms is missing
```

## Software Stack

| Category       | Application              | Package                   | Description                                  |
| :------------- | :----------------------- | :------------------------ | :------------------------------------------- |
| Window Manager | Niri                     | `niri`                    | Scrollable tiling Wayland compositor.        |
| Shell UI       | DankMaterialShell        | official installer        | Panel, launcher, widgets, and desktop shell. |
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

If colors or generated theme files look stale, change the wallpaper from
DankMaterialShell and let it regenerate the theme outputs.

More chezmoi mapping details live in [CHEZMOI.md](CHEZMOI.md).

## Manual Steps After Install

1. Log in to Zen Browser, Vesktop, Spotify, VSCodium Sync, GitHub CLI, and Tailscale.
2. Run `sudo tailscale up` if Tailscale has not been authenticated yet.
3. Change the wallpaper in DankMaterialShell if generated colors or theme files look stale.
4. Open DankMaterialShell settings if the shell uses default layout or theme values after first launch.
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

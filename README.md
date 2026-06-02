# 🍙 My CachyOS Dotfiles

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Niri](https://img.shields.io/badge/Niri-WM-ff69b4?style=for-the-badge)
![Managed by Chezmoi](https://img.shields.io/badge/chezmoi-000000?style=for-the-badge&logo=chezmoi&logoColor=white)

My personal configuration for **Arch**, featuring the **Niri** window manager and **DankMaterialShell**. Managed with [chezmoi](https://www.chezmoi.io/).

## 🚀 One-Line Install (Fresh Machine)

To install this setup on a fresh Arch machine, open a terminal and run:

Replace "navier" with your github username.

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply navier
```

## 🛠️ Software Stack

The installation script automatically sets up the following environment:

| Category           | Application         | Package Name              | Description                                   |
| :----------------- | :------------------ | :------------------------ | :-------------------------------------------- |
| **Window Manager** | Niri                | `niri`                    | Infinite scrollable tiling window manager.    |
| **Shell UI**       | DankMaterialShell   | `dms-shell-bin`           | Custom shell with Quick Settings & Bar.       |
| **Terminal**       | Kitty               | `kitty`                   | Terminal.                                     |
| **Browser**        | Zen Browser         | `zen-browser-bin`         | Privacy-focused, vertical-tab Firefox fork.   |
| **Editor**         | VS Codium           | `vscodium-bin`            | Free Open Source Software Binaries of VSCode. |
| **Chat**           | Discord             | `discord`                 | Standard Discord client.                      |
| **Music**          | Spotify             | `spotify`                 | Music streaming.                              |
| **Maintenance**    | BleachBit           | `bleachbit`               | System cleaner and space freer.               |
| **Fonts**          | JetBrains Mono      | `ttf-jetbrains-mono-nerd` | Patched Nerd Font for terminal icons.         |
| **Theme**          | Adwaita Dark        | `adw-gtk-theme`           | Bridges GTK3 apps to Libadwaita style.        |
| **Cursor**         | MacOS TahoeX Cursor | `MacOS TahoeX Cursor`     | MacOS Tahoe Cursor.                           |

---

## 🎨 Theming & Appearance

This setup enforces a consistent **Dark Mode** across the system.

-   **GTK Applications:** The installer automatically applies `adw-gtk3-dark` and sets the color scheme to `prefer-dark`. This ensures legacy apps (like BleachBit or Pavucontrol) match modern Libadwaita apps (like Zen or Nautilus).
-   **Terminal Icons:** `ttf-jetbrains-mono-nerd` is installed by default. If you see "squares" instead of icons in your terminal, ensure your terminal font is set to **JetBrainsMono Nerd Font**.

---

## ⚠️ Manual Steps (After Install)

While Chezmoi handles 95% of the setup, you will need to do these things manually after the first boot:

1.  **Logins:** Log into Zen Browser (Sync), Discord, Spotify, and VS Code Sync.
2.  **DankMaterialShell:** If the shell looks "default," you may need to reload it or select your preferred layout in the DMS settings menu once.

---

## ❓ Troubleshooting

**"The installer failed on a package!"**
If the script stops mid-way, you can resume it or install the missing package manually:

```bash
paru -S package_name
chezmoi apply
```

---

## 📖 Daily Workflow (Cheat Sheet)

### 1️⃣ Edit a Config (The Right Way)

chezmoi edit --apply ~/.config/niri/config.kdl

```bash
chezmoi edit --apply ~/.config/niri/config.kdl
```

### 2️⃣ Save Visual/GUI Changes

```bash
# Example: After changing DMS theme
chezmoi add ~/.config/DankMaterialShell
```

### 3️⃣ Add New Software

To add a new app to the auto-installer script:

1. `chezmoi cd`
2. Edit `run_once_before_install_packages.sh`
3. Add the package name to the list.

### 4️⃣ Push Changes to GitHub

```bash
chezmoi cd
git add .
git commit -m "Updated configs"
git push
```

## TODO:
[ ] Fix behavior for overview when changing wallpaper
[ ] Migrate to chezmoi
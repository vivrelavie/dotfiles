#!/usr/bin/env bash
set -Eeuo pipefail

# CachyOS/Arch bootstrap script for this chezmoi-managed desktop setup.
# The script is intentionally idempotent where practical: package installs use
# --needed, existing app configs are not overwritten, and optional desktop
# settings are skipped when their command-line tools are unavailable.

# Packages requested for the base desktop. Arch provides the SSH daemon through
# the openssh package, so "sshd" is handled by installing openssh and enabling
# sshd.service later in the script.
PACKAGES=(
    "kitty"                    # Terminal
    "fish"                     # Shell
    "fastfetch"                # System info
    "yazi"                     # Terminal file manager
    "ttf-jetbrains-mono"       # Font
    "ttf-jetbrains-mono-nerd"  # Nerd Font
    "adw-gtk-theme"            # GTK3 theme aligned with Libadwaita
    "zen-browser-bin"          # Browser
    "vscodium-bin"             # Editor
    "vesktop-bin"              # Discord client
    "spotify"                  # Music
    "bleachbit"                # Cleanup tool
    "obs-studio"               # Recording and streaming
    "localsend-bin"            # Local file sharing
    "openssh"                  # Provides sshd
    "tailscale"                # Mesh VPN
    "neovim"                   # Editor
    "github-cli"               # GitHub CLI
)

# Commands needed by later installer steps.
SCRIPT_DEPS=(
    "curl"
    "git"
)

DMS_INSTALLER_URL="https://install.danklinux.com"
LAZYVIM_STARTER_URL="https://github.com/LazyVim/starter.git"
TEMP_DIRS=()
CURRENT_STEP="startup"

# Status helpers keep output consistent and easy to scan during a fresh install.
status_start() {
    printf '[..] %s\n' "$*"
}

status_done() {
    printf '[OK] %s\n' "$*"
}

status_skip() {
    printf '[-] %s\n' "$*"
}

status_warn() {
    printf '[!] %s\n' "$*" >&2
}

status_fail() {
    printf '[FAIL] %s\n' "$*" >&2
}

die() {
    status_fail "$*"
    exit 1
}

# Run a named install phase and report start/finish. If the command fails,
# set -e and the ERR trap report the failed phase before exiting.
run_step() {
    local description="$1"

    shift
    CURRENT_STEP="$description"
    status_start "$description"
    "$@"
    status_done "$description finished."
}

# Remove temporary AUR checkout and downloaded installer files on exit.
cleanup() {
    local dir

    for dir in "${TEMP_DIRS[@]}"; do
        if [[ -n "$dir" && -d "$dir" ]]; then
            rm -rf "$dir"
        fi
    done
}

# Print a clear failure message for unsuccessful installs, including the phase
# and command Bash was running when the error occurred.
handle_error() {
    local exit_code=$?
    local line_number="${1:-unknown}"
    local command="${2:-unknown}"

    status_fail "Install did not finish successfully."
    status_fail "Failed during step: $CURRENT_STEP"
    status_fail "Line $line_number exited with code $exit_code: $command"
    exit "$exit_code"
}

make_temp_dir() {
    local dir

    dir="$(mktemp -d)"
    TEMP_DIRS+=("$dir")
    printf '%s\n' "$dir"
}

has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Basic preflight checks avoid running package-manager logic on the wrong OS.
require_cachyos_or_arch() {
    has_command pacman || die "pacman not found. This script is intended for CachyOS/Arch systems."
    has_command sudo || die "sudo not found."

    if [[ ! -r /etc/arch-release ]]; then
        status_warn "This does not look like an Arch-based system. Continuing because pacman exists."
    fi
}

# Prompt for sudo once near the beginning so later service/package steps can run.
refresh_sudo() {
    sudo -v
}

# yay is used for both repo packages and AUR packages. If it is missing, build
# it from the official AUR package recipe in a temporary directory.
install_yay() {
    local build_dir

    if has_command yay; then
        status_skip "yay is already installed."
        return
    fi

    status_start "yay not found. Installing yay from the AUR."
    sudo pacman -S --needed --noconfirm base-devel git

    build_dir="$(make_temp_dir)"
    git clone https://aur.archlinux.org/yay.git "$build_dir/yay"

    (
        cd "$build_dir/yay"
        makepkg -si --noconfirm
    )
}

install_packages() {
    status_start "Installing applications, fonts, services, and script dependencies with yay."
    yay -S --needed --noconfirm "${SCRIPT_DEPS[@]}" "${PACKAGES[@]}"
}

# Apply the GTK theme immediately for environments where gsettings is available.
apply_gtk_theme() {
    if ! has_command gsettings; then
        status_skip "gsettings not found. Skipping GTK theme and dark-mode settings."
        return
    fi

    status_start "Applying Adw-GTK3 dark theme."
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}

# Remove stock Firefox when present, leaving Zen Browser as the browser choice.
remove_firefox() {
    if pacman -Qq firefox >/dev/null 2>&1; then
        status_start "Firefox is installed. Removing Firefox."
        sudo pacman -Rns --noconfirm firefox
        return
    fi

    status_skip "Firefox is already absent."
}

# Enable a service only when systemd and the service unit exist.
enable_service() {
    local service="$1"

    if ! has_command systemctl; then
        status_skip "systemctl not found. Skipping $service."
        return
    fi

    if ! systemctl list-unit-files "$service" >/dev/null 2>&1; then
        status_skip "$service was not found. Skipping enable/start."
        return
    fi

    status_start "Enabling and starting $service."
    sudo systemctl enable --now "$service"
    status_done "$service is enabled and running."
}

enable_services() {
    enable_service sshd.service
    enable_service tailscaled.service
}

# Install LazyVim's starter config only when Neovim does not already have a
# config directory. This avoids overwriting personal editor configuration.
install_lazyvim() {
    local nvim_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

    if [[ -e "$nvim_dir" ]]; then
        status_skip "Neovim config already exists at $nvim_dir. Skipping LazyVim starter install."
        return
    fi

    status_start "Installing LazyVim starter config."
    mkdir -p "$(dirname "$nvim_dir")"
    git clone --depth 1 "$LAZYVIM_STARTER_URL" "$nvim_dir"
    rm -rf "$nvim_dir/.git"
}

# The official DankMaterialShell installer is downloaded to a temp file first so
# failures are clearer than a direct curl-to-shell pipeline.
install_dank_material_shell() {
    local installer
    local installer_dir

    if has_command dms; then
        status_skip "DankMaterialShell is already installed."
        return
    fi

    status_start "Installing DankMaterialShell with the official installer."
    installer_dir="$(make_temp_dir)"
    installer="$installer_dir/install-dank-material-shell.sh"

    curl -fsSL "$DMS_INSTALLER_URL" -o "$installer"
    sh "$installer"
}

ensure_niri_dms_include_files() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
    local niri_dms_dir="$config_home/niri/dms"
    local niri_focus_file="$cache_home/DankMaterialShell/niri-focus.kdl"
    local file
    local target

    mkdir -p "$niri_dms_dir" "$(dirname "$niri_focus_file")"

    for file in binds.kdl cursor.kdl windowrules.kdl wpblur.kdl; do
        target="$niri_dms_dir/$file"
        if [[ ! -e "$target" ]]; then
            : > "$target"
        fi
    done

    if [[ ! -e "$niri_focus_file" ]]; then
        cat > "$niri_focus_file" <<'KDL'
layout {
    focus-ring {
        active-color "#edb4eb"
    }
}
KDL
    fi
}

main() {
    trap cleanup EXIT
    trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR

    status_start "Starting CachyOS master setup."
    run_step "Checking system requirements" require_cachyos_or_arch
    run_step "Requesting sudo access" refresh_sudo
    run_step "Checking yay installation" install_yay
    run_step "Installing package list" install_packages
    run_step "Applying GTK theme settings" apply_gtk_theme
    run_step "Checking Firefox removal" remove_firefox
    run_step "Enabling system services" enable_services
    run_step "Checking LazyVim starter config" install_lazyvim
    run_step "Checking DankMaterialShell installation" install_dank_material_shell
    run_step "Ensuring Niri/DMS include files" ensure_niri_dms_include_files
    status_done "Software installation complete."
}

main "$@"

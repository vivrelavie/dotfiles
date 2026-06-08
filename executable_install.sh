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

NOCTALIA_V4_PACKAGES=(
    "noctalia-shell"           # Stable Quickshell-based Noctalia shell
)

NOCTALIA_V5_PACKAGES=(
    "noctalia-git"             # Alpha native Noctalia shell
)

# Stock Niri-session helper apps that are replaced by DankMaterialShell or this
# repo's app choices.
UNUSED_NIRI_DEFAULT_PACKAGES=(
    "alacritty"                # Replaced by Kitty
    "fuzzel"                   # Replaced by DMS Spotlight/app launcher
    "mako"                     # Replaced by DMS notifications
    "swaybg"                   # Replaced by DMS wallpaper handling
    "swayidle"                 # Replaced by DMS session controls
    "swaylock"                 # Replaced by DMS lock screen
    "waybar"                   # Replaced by DMS bar/shell UI
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
DESKTOP_SHELL="${DESKTOP_SHELL:-}"
ASSUME_YES=false
INSTALL_REVIEW_DOTFILES=true
INSTALL_BASE_PACKAGES=true
INSTALL_DESKTOP_SHELL=true
INSTALL_APPLY_GTK_THEME=true
INSTALL_REMOVE_FIREFOX=true
INSTALL_ENABLE_SERVICES=true
INSTALL_LAZYVIM=true
INSTALL_REMOVE_UNUSED_NIRI_DEFAULTS=false
INSTALL_ENSURE_NIRI_DMS_INCLUDES=false
SELECTED_PACKAGES=()

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

bool_label() {
    if [[ "$1" == true ]]; then
        printf '[x]'
    else
        printf '[ ]'
    fi
}

find_chezmoi() {
    if has_command chezmoi; then
        command -v chezmoi
        return
    fi

    if [[ -x "$HOME/bin/chezmoi" ]]; then
        printf '%s\n' "$HOME/bin/chezmoi"
        return
    fi

    if [[ -x "$HOME/.local/bin/chezmoi" ]]; then
        printf '%s\n' "$HOME/.local/bin/chezmoi"
        return
    fi

    return 1
}

is_supported_desktop_shell() {
    case "$1" in
        dms | noctalia-v4 | noctalia-v5 | none)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

set_desktop_shell() {
    local desktop_shell="$1"

    is_supported_desktop_shell "$desktop_shell" || die "Unsupported desktop shell profile: $desktop_shell"

    DESKTOP_SHELL="$desktop_shell"
    INSTALL_REMOVE_UNUSED_NIRI_DEFAULTS=false
    INSTALL_ENSURE_NIRI_DMS_INCLUDES=false

    if [[ "$DESKTOP_SHELL" == dms ]]; then
        INSTALL_REMOVE_UNUSED_NIRI_DEFAULTS=true
        INSTALL_ENSURE_NIRI_DMS_INCLUDES=true
    fi
}

detect_desktop_shell() {
    local chezmoi_cmd
    local detected_shell

    if [[ -n "$DESKTOP_SHELL" ]]; then
        set_desktop_shell "$DESKTOP_SHELL"
        return
    fi

    if chezmoi_cmd="$(find_chezmoi)"; then
        detected_shell="$("$chezmoi_cmd" execute-template '{{ get . "desktop_shell" | default "dms" }}' 2>/dev/null || true)"
    fi

    set_desktop_shell "${detected_shell:-dms}"
}

usage() {
    cat <<'USAGE'
Usage: install.sh [options]

Options:
  -y, --yes                         Use the detected/default install plan without the review menu.
      --desktop-shell <profile>     Override profile for this run: dms, noctalia-v4, noctalia-v5, none.
      --no-dotfiles-review          Do not run the optional chezmoi diff/apply review.
  -h, --help                        Show this help.

Environment:
  DESKTOP_SHELL=dms|noctalia-v4|noctalia-v5|none
USAGE
}

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -y | --yes)
                ASSUME_YES=true
                ;;
            --desktop-shell)
                shift
                [[ "$#" -gt 0 ]] || die "--desktop-shell requires a profile."
                set_desktop_shell "$1"
                ;;
            --desktop-shell=*)
                set_desktop_shell "${1#*=}"
                ;;
            --no-dotfiles-review)
                INSTALL_REVIEW_DOTFILES=false
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
        shift
    done
}

toggle_bool() {
    local name="$1"

    if [[ "${!name}" == true ]]; then
        printf -v "$name" '%s' false
    else
        printf -v "$name" '%s' true
    fi
}

choose_desktop_shell() {
    local choice
    local changed=false

    printf '\nDesktop shell profile:\n'
    printf '  1) dms          DankMaterialShell\n'
    printf '  2) noctalia-v4  Stable Quickshell-based Noctalia\n'
    printf '  3) noctalia-v5  Alpha native Noctalia\n'
    printf '  4) none         Keep shared Niri config without a desktop shell\n'
    printf 'Choose [1-4]: '
    read -r choice

    case "$choice" in
        1) set_desktop_shell dms; changed=true ;;
        2) set_desktop_shell noctalia-v4; changed=true ;;
        3) set_desktop_shell noctalia-v5; changed=true ;;
        4) set_desktop_shell none; changed=true ;;
        *) status_warn "Unknown desktop shell choice: $choice" ;;
    esac

    if [[ "$changed" == true ]]; then
        status_warn "Desktop shell changes made here apply to this installer run. Choose during chezmoi init to persist the profile."
    fi
}

build_selected_packages() {
    SELECTED_PACKAGES=()

    if [[ "$INSTALL_BASE_PACKAGES" == true || ( "$INSTALL_DESKTOP_SHELL" == true && "$DESKTOP_SHELL" != none ) ]]; then
        SELECTED_PACKAGES+=("${SCRIPT_DEPS[@]}")
    fi

    if [[ "$INSTALL_BASE_PACKAGES" == true ]]; then
        SELECTED_PACKAGES+=("${PACKAGES[@]}")
    fi

    if [[ "$INSTALL_DESKTOP_SHELL" == true ]]; then
        case "$DESKTOP_SHELL" in
            noctalia-v4)
                SELECTED_PACKAGES+=("${NOCTALIA_V4_PACKAGES[@]}")
                ;;
            noctalia-v5)
                SELECTED_PACKAGES+=("${NOCTALIA_V5_PACKAGES[@]}")
                ;;
        esac
    fi
}

needs_yay() {
    build_selected_packages
    [[ "${#SELECTED_PACKAGES[@]}" -gt 0 ]]
}

show_selected_packages() {
    local package

    build_selected_packages

    printf '\nSelected yay packages:\n'
    if [[ "${#SELECTED_PACKAGES[@]}" -eq 0 ]]; then
        printf '  none\n'
    else
        for package in "${SELECTED_PACKAGES[@]}"; do
            printf '  - %s\n' "$package"
        done
    fi

    if [[ "$INSTALL_DESKTOP_SHELL" == true && "$DESKTOP_SHELL" == dms ]]; then
        printf '\nExternal installer:\n'
        printf '  - DankMaterialShell via %s\n' "$DMS_INSTALLER_URL"
    fi
}

print_install_plan() {
    printf '\nInstall plan\n'
    printf '  Desktop shell profile: %s\n' "$DESKTOP_SHELL"
    printf '  1) Change desktop shell profile for this run\n'
    printf '  2) %s Review/apply chezmoi file changes interactively\n' "$(bool_label "$INSTALL_REVIEW_DOTFILES")"
    printf '  3) %s Install base package list\n' "$(bool_label "$INSTALL_BASE_PACKAGES")"
    printf '  4) %s Install selected desktop shell\n' "$(bool_label "$INSTALL_DESKTOP_SHELL")"
    printf '  5) %s Apply GTK theme settings\n' "$(bool_label "$INSTALL_APPLY_GTK_THEME")"
    printf '  6) %s Remove Firefox\n' "$(bool_label "$INSTALL_REMOVE_FIREFOX")"
    printf '  7) %s Enable sshd/tailscaled services\n' "$(bool_label "$INSTALL_ENABLE_SERVICES")"
    printf '  8) %s Install LazyVim starter if missing\n' "$(bool_label "$INSTALL_LAZYVIM")"
    printf '  9) %s Remove DMS-replaced stock Niri packages\n' "$(bool_label "$INSTALL_REMOVE_UNUSED_NIRI_DEFAULTS")"
    printf ' 10) %s Ensure DMS/Niri generated include stubs\n' "$(bool_label "$INSTALL_ENSURE_NIRI_DMS_INCLUDES")"
}

review_install_plan() {
    local choice

    if [[ "$ASSUME_YES" == true ]]; then
        status_skip "Using install plan without interactive review because --yes was provided."
        return
    fi

    if [[ ! -t 0 ]]; then
        status_skip "No interactive terminal detected. Using install plan as-is."
        return
    fi

    while true; do
        print_install_plan
        printf '\nEnter a number to change/toggle, p to show packages, c to continue, q to quit: '
        read -r choice

        case "$choice" in
            1) choose_desktop_shell ;;
            2) toggle_bool INSTALL_REVIEW_DOTFILES ;;
            3) toggle_bool INSTALL_BASE_PACKAGES ;;
            4) toggle_bool INSTALL_DESKTOP_SHELL ;;
            5) toggle_bool INSTALL_APPLY_GTK_THEME ;;
            6) toggle_bool INSTALL_REMOVE_FIREFOX ;;
            7) toggle_bool INSTALL_ENABLE_SERVICES ;;
            8) toggle_bool INSTALL_LAZYVIM ;;
            9) toggle_bool INSTALL_REMOVE_UNUSED_NIRI_DEFAULTS ;;
            10) toggle_bool INSTALL_ENSURE_NIRI_DMS_INCLUDES ;;
            p | P) show_selected_packages ;;
            c | C) break ;;
            q | Q) die "Install cancelled by user." ;;
            *) status_warn "Unknown choice: $choice" ;;
        esac
    done
}

review_chezmoi_changes() {
    local chezmoi_cmd
    local override_data

    if ! chezmoi_cmd="$(find_chezmoi)"; then
        status_skip "chezmoi not found. Skipping file review."
        return
    fi

    override_data="{\"desktop_shell\":\"$DESKTOP_SHELL\"}"

    status_start "Showing chezmoi file changes."
    "$chezmoi_cmd" diff --no-pager --override-data "$override_data" || true

    if [[ "$ASSUME_YES" == true ]]; then
        status_start "Applying chezmoi changes with --force because --yes was provided."
        "$chezmoi_cmd" apply --force --override-data "$override_data"
        return
    fi

    if [[ ! -t 0 ]]; then
        status_skip "No interactive terminal detected. Skipping chezmoi apply."
        return
    fi

    printf '\nRun chezmoi apply --interactive now? [Y/n] '
    read -r reply
    case "$reply" in
        n | N | no | NO | No)
            status_skip "Skipping chezmoi apply."
            ;;
        *)
            "$chezmoi_cmd" apply --interactive --override-data "$override_data"
            ;;
    esac
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
    build_selected_packages

    if [[ "${#SELECTED_PACKAGES[@]}" -eq 0 ]]; then
        status_skip "No yay packages selected."
        return
    fi

    status_start "Installing selected packages with yay."
    yay -S --needed --noconfirm "${SELECTED_PACKAGES[@]}"
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

# Remove packages commonly installed by stock Niri desktop profiles when DMS
# owns the corresponding bar, launcher, notification, wallpaper, and lock flows.
remove_unused_niri_default_packages() {
    local package
    local installed_packages=()

    for package in "${UNUSED_NIRI_DEFAULT_PACKAGES[@]}"; do
        if pacman -Qq "$package" >/dev/null 2>&1; then
            installed_packages+=("$package")
        fi
    done

    if [[ "${#installed_packages[@]}" -eq 0 ]]; then
        status_skip "Unused stock Niri packages are already absent."
        return
    fi

    status_start "Removing unused stock Niri packages: ${installed_packages[*]}."
    sudo pacman -Rns --noconfirm "${installed_packages[@]}"
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

run_optional_step() {
    local enabled="$1"
    local description="$2"

    shift 2

    if [[ "$enabled" == true ]]; then
        run_step "$description" "$@"
    else
        status_skip "$description skipped by install plan."
    fi
}

main() {
    trap cleanup EXIT
    trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR

    parse_args "$@"
    detect_desktop_shell

    status_start "Starting CachyOS master setup."
    run_step "Checking system requirements" require_cachyos_or_arch
    review_install_plan
    run_optional_step "$INSTALL_REVIEW_DOTFILES" "Reviewing chezmoi file changes" review_chezmoi_changes
    run_step "Requesting sudo access" refresh_sudo

    if needs_yay; then
        run_step "Checking yay installation" install_yay
        run_step "Installing package list" install_packages
    else
        status_skip "No yay packages selected. Skipping yay setup and package installation."
    fi

    run_optional_step "$INSTALL_APPLY_GTK_THEME" "Applying GTK theme settings" apply_gtk_theme
    run_optional_step "$INSTALL_REMOVE_FIREFOX" "Checking Firefox removal" remove_firefox
    run_optional_step "$INSTALL_ENABLE_SERVICES" "Enabling system services" enable_services
    run_optional_step "$INSTALL_LAZYVIM" "Checking LazyVim starter config" install_lazyvim

    if [[ "$DESKTOP_SHELL" == dms ]]; then
        run_optional_step "$INSTALL_DESKTOP_SHELL" "Checking DankMaterialShell installation" install_dank_material_shell
    else
        status_skip "DankMaterialShell installer skipped for desktop shell profile: $DESKTOP_SHELL."
    fi

    run_optional_step "$INSTALL_REMOVE_UNUSED_NIRI_DEFAULTS" "Removing unused stock Niri packages" remove_unused_niri_default_packages
    run_optional_step "$INSTALL_ENSURE_NIRI_DMS_INCLUDES" "Ensuring Niri/DMS include files" ensure_niri_dms_include_files
    status_done "Software installation complete."
}

main "$@"

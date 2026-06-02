#!/usr/bin/env bash
set -euo pipefail

cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/niri-focus.kdl"
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"

if [[ ! -f "$cache_file" ]]; then
    printf 'missing generated niri focus color file: %s\n' "$cache_file" >&2
    exit 1
fi

if [[ ! -f "$config_file" ]]; then
    printf 'missing niri config file: %s\n' "$config_file" >&2
    exit 1
fi

target_file="$(realpath "$config_file")"

color="$(
    sed -n 's/.*active-color "\(#[0-9A-Fa-f]\{6,8\}\)".*/\1/p; t found; b; :found; q' "$cache_file"
)"

if [[ ! "$color" =~ ^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$ ]]; then
    printf 'invalid active color in %s: %s\n' "$cache_file" "${color:-<empty>}" >&2
    exit 1
fi

if ! grep -Eq '^[[:space:]]*include "~/.cache/DankMaterialShell/niri-focus\.kdl"' "$target_file"; then
    printf 'missing niri focus include in config: %s\n' "$target_file" >&2
    exit 1
fi

niri validate -c "$target_file" >/dev/null
niri msg action load-config-file

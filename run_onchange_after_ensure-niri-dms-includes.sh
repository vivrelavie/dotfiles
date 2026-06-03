#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
niri_dms_dir="$config_home/niri/dms"
niri_focus_file="$cache_home/DankMaterialShell/niri-focus.kdl"

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

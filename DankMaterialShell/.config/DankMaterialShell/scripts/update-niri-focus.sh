#!/bin/bash
COLOR=$(python3 -c "
import json
with open('/home/stef/.cache/DankMaterialShell/niri-focus.kdl') as f:
    for line in f:
        if 'active-color' in line:
            print(line.strip().split('\"')[1])
")
sed -i 's/^        active-color "#[0-9a-fA-F]*"/        active-color "'"$COLOR"'"/' ~/.config/niri/config.kdl
niri msg action load-config-file

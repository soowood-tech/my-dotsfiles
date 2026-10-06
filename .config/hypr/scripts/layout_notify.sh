#!/usr/bin/env bash
# Listen to Hyprland layout change events and send notification

SOCAT_SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ ! -S "$SOCAT_SOCK" ]]; then
    exit 1
fi

socat -u "UNIX-CONNECT:$SOCAT_SOCK" - | while read -r line; do
    if [[ "$line" == activelayout* ]]; then
        layout="${line#*,}"
        notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -t 1000 "Раскладка" "$layout"
    fi
done

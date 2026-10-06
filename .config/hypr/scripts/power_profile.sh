#!/usr/bin/env bash

# Cycle power profiles: balanced -> performance -> power-saver -> balanced
STATE_FILE="$HOME/.cache/power_profile_state"

get_current() {
    if command -v powerprofilesctl &>/dev/null && systemctl is-active --quiet power-profiles-daemon; then
        powerprofilesctl get 2>/dev/null
    elif [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    elif [[ -r /sys/firmware/acpi/platform_profile ]]; then
        cat /sys/firmware/acpi/platform_profile 2>/dev/null
    else
        echo "balanced"
    fi
}

current=$(get_current)

case "$current" in
    "balanced"|"balance")
        target_profile="performance"
        target_sys="performance"
        title="Производительность"
        msg="Режим высокой производительности активирован"
        icon="speedometer"
        ;;
    "performance")
        target_profile="power-saver"
        target_sys="quiet"
        title="Экономия энергии"
        msg="Режим энергосбережения активирован"
        icon="battery-low"
        ;;
    "power-saver"|"quiet"|"powersave"|*)
        target_profile="balanced"
        target_sys="balanced"
        title="Сбалансированный (Стабильный)"
        msg="Стабильный сбалансированный режим активирован"
        icon="battery"
        ;;
esac

# Save current state
echo "$target_profile" > "$STATE_FILE"

# 1. Apply via powerprofilesctl if available and active
if command -v powerprofilesctl &>/dev/null && systemctl is-active --quiet power-profiles-daemon; then
    powerprofilesctl set "$target_profile" 2>/dev/null
fi

# 2. Apply via sysfs platform_profile if accessible
if [[ -w /sys/firmware/acpi/platform_profile ]]; then
    echo "$target_sys" > /sys/firmware/acpi/platform_profile 2>/dev/null
fi

# 3. Notification popup with matching theme
notify-send -h string:x-canonical-private-synchronous:power-profile \
            -u normal \
            -t 2000 \
            -i "$icon" \
            "Режим питания: $title" \
            "$msg"

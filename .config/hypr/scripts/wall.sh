#!/usr/bin/env bash
# ==============================================================================
# Dynamic Wallpaper & Color Scheme Setter for Hyprland + Waybar + Kitty + SDDM
# ==============================================================================

WALLPAPER_DIR="$HOME/Pictures/Pixel"
[[ ! -d "$WALLPAPER_DIR" ]] && WALLPAPER_DIR="$HOME/Pictures"

STATE_FILE="$HOME/.cache/current_wallpaper"
BACKUP_STATE_FILE="$HOME/.config/hypr/current_wallpaper"
SDDM_LOCAL_THEME="$HOME/.config/sddm-theme"
SDDM_SYSTEM_THEME="/usr/share/sddm/themes/hypr-sync"

MODE="$1"

if [[ "$MODE" == "--restore" || "$MODE" == "-r" ]]; then
    # Restore mode (used on Hyprland startup to NOT change wallpaper)
    if [[ -f "$STATE_FILE" && -s "$STATE_FILE" ]]; then
        WALL=$(cat "$STATE_FILE")
    elif [[ -f "$BACKUP_STATE_FILE" && -s "$BACKUP_STATE_FILE" ]]; then
        WALL=$(cat "$BACKUP_STATE_FILE")
    fi

    # If state file didn't point to a valid file, check what awww is currently displaying
    if [[ -z "$WALL" || ! -f "$WALL" ]] && which awww &>/dev/null; then
        CURRENT_AWWW=$(awww query 2>/dev/null | grep -o 'image: .*' | head -n 1 | sed 's/image: //')
        if [[ -n "$CURRENT_AWWW" && -f "$CURRENT_AWWW" ]]; then
            WALL="$CURRENT_AWWW"
        fi
    fi

    # Fallback to first available wallpaper if no state exists
    if [[ -z "$WALL" || ! -f "$WALL" ]]; then
        WALL=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | head -n 1)
    fi
elif [[ -n "$1" && -f "$1" ]]; then
    # Specific image specified
    WALL="$1"
else
    # Pick a random wallpaper (when user presses Super+W or passes --random)
    WALL=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
fi

if [[ -z "$WALL" || ! -f "$WALL" ]]; then
    echo "Обои не найдены в $WALLPAPER_DIR"
    exit 1
fi

echo "Применение обоев: $WALL"

# Save state so on next Hyprland startup the wallpaper DOES NOT change
mkdir -p "$(dirname "$STATE_FILE")" "$(dirname "$BACKUP_STATE_FILE")"
echo "$WALL" > "$STATE_FILE"
echo "$WALL" > "$BACKUP_STATE_FILE"

# 1. Извлекаем палитру и генерируем цвета (Waybar, Hyprland, Foot, Kitty, SDDM, etc.)
python3 "$HOME/.config/hypr/scripts/pywal_theme.py" "$WALL"

# 2. Копируем обои в тему SDDM (локальную и системную)
mkdir -p "$SDDM_LOCAL_THEME"
cp -f "$WALL" "$SDDM_LOCAL_THEME/wallpaper.jpg"

if [[ -d "$SDDM_SYSTEM_THEME" && -w "$SDDM_SYSTEM_THEME" ]]; then
    cp -f "$WALL" "$SDDM_SYSTEM_THEME/wallpaper.jpg"
    chmod 644 "$SDDM_SYSTEM_THEME/wallpaper.jpg" 2>/dev/null || true
fi

# 3. Устанавливаем обои в Hyprland
if which awww &>/dev/null; then
    if ! pgrep -x awww-daemon >/dev/null && ! pgrep -x awww >/dev/null; then
        awww-daemon &>/dev/null &
        sleep 0.5
    fi
    if [[ "$MODE" == "--restore" || "$MODE" == "-r" ]]; then
        # On restore, set without slow wipe
        awww img "$WALL" || true
    else
        awww img "$WALL" --transition-type wipe --transition-angle 30 --transition-step 90 --transition-duration 1.2 || awww img "$WALL"
    fi
elif which swww &>/dev/null; then
    if ! pgrep -x swww-daemon >/dev/null; then
        swww-daemon &
        sleep 0.5
    fi
    swww img "$WALL" --transition-type wipe --transition-angle 30 --transition-step 90 --transition-duration 1.2
elif which hyprpaper &>/dev/null; then
    pkill hyprpaper || true
    echo -e "preload = $WALL\nwallpaper = ,$WALL" > "$HOME/.config/hypr/hyprpaper.conf"
    hyprpaper &
elif which swaybg &>/dev/null; then
    pkill swaybg || true
    swaybg -i "$WALL" -m fill &
fi

# 4. Перезагружаем цвета в Waybar
if pgrep -x waybar >/dev/null; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
fi

# 5. Обновляем Kitty и Foot
pkill -SIGUSR1 kitty 2>/dev/null || true
pkill -SIGUSR1 foot 2>/dev/null || true

# 6. Уведомление
if [[ "$MODE" != "--restore" && "$MODE" != "-r" ]]; then
    notify-send -i "$WALL" "Обои и палитра обновлены" "$(basename "$WALL")" 2>/dev/null || true
fi

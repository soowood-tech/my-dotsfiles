#!/usr/bin/env bash
# ==============================================================================
# Installer for hypr-sync SDDM Theme
# ==============================================================================
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Пожалуйста, запустите этот скрипт с sudo:"
    echo "  sudo ~/.config/sddm-theme/install_sddm.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/Main.qml" ]]; then
    SRC_DIR="$SCRIPT_DIR"
elif [[ -f "/home/$REAL_USER/.config/sddm-theme/Main.qml" ]]; then
    SRC_DIR="/home/$REAL_USER/.config/sddm-theme"
else
    SRC_DIR="$HOME/.config/sddm-theme"
fi
TARGET_DIR="/usr/share/sddm/themes/hypr-sync"
CONFD_DIR="/etc/sddm.conf.d"
CONF_FILE="$CONFD_DIR/zzz-hypr-sync.conf"

echo "=== Установка темы SDDM hypr-sync ==="
mkdir -p "$TARGET_DIR"

# Copy theme files
cp -f "$SRC_DIR/metadata.desktop" "$TARGET_DIR/"
cp -f "$SRC_DIR/Main.qml" "$TARGET_DIR/"
[[ -f "$SRC_DIR/theme.conf" ]] && cp -f "$SRC_DIR/theme.conf" "$TARGET_DIR/"
[[ -f "$SRC_DIR/wallpaper.jpg" ]] && cp -f "$SRC_DIR/wallpaper.jpg" "$TARGET_DIR/"

# Give ownership to the user so Hyprland can update wallpaper and colors dynamically without sudo!
chown -R "$REAL_USER:$REAL_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"
chmod 644 "$TARGET_DIR"/*

# Configure SDDM
mkdir -p "$CONFD_DIR"
cat << 'EOF' > "$CONF_FILE"
[Theme]
Current=hypr-sync
CursorTheme=capitaine-cursors
EOF
chmod 644 "$CONF_FILE"

# If an older drop-in exists, update or backup to avoid conflicts
if [[ -f "$CONFD_DIR/zz-pixelstreetart.conf" ]]; then
    sed -i 's/^Current=.*/Current=hypr-sync/' "$CONFD_DIR/zz-pixelstreetart.conf" 2>/dev/null || true
fi

echo "✓ Тема hypr-sync успешно установлена в $TARGET_DIR"
echo "✓ Настройка сохранена в $CONF_FILE"
echo "✓ Пользователь $REAL_USER имеет права на динамическое обновление обоев и цветов"

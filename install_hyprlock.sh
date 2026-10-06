#!/usr/bin/env bash
# ==============================================================================
# Script to install hyprlock screen locker
# ==============================================================================
set -e

echo ":: Проверка и установка hyprlock..."
if command -v pacman &>/dev/null; then
    sudo pacman -S --needed hyprlock
    echo "✓ hyprlock успешно установлен!"
    echo "  Горячая клавиша: SUPER + L"
elif command -v yay &>/dev/null; then
    yay -S --needed hyprlock
    echo "✓ hyprlock успешно установлен!"
    echo "  Горячая клавиша: SUPER + L"
else
    echo "✗ Пакетный менеджер не найден. Установите hyprlock вручную."
    exit 1
fi

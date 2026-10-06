#!/usr/bin/env bash

# Rofi Power Menu for Hyprland & Waybar

chosen=$(echo -e "⏻  Выключение\n  Перезагрузка\n󰌾  Заблокировать\n󰤄  Спящий режим\n󰍃  Выход из сессии" | rofi -dmenu -p "Питание" -theme-str 'window {width: 320px; height: 300px;}')

case "$chosen" in
    *"Выключение"*)
        systemctl poweroff
        ;;
    *"Перезагрузка"*)
        systemctl reboot
        ;;
    *"Заблокировать"*)
        hyprlock
        ;;
    *"Спящий режим"*)
        systemctl suspend
        ;;
    *"Выход из сессии"*)
        hyprctl dispatch exit
        ;;
esac

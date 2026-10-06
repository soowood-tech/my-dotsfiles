#!/usr/bin/env bash
# ==============================================================================
#  My-Dotsfiles Auto-Installer (Hyprland + Waybar + SDDM + Dynamic Rice)
# ==============================================================================
set -e

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/dots_backup_$(date +%Y%m%d_%H%M%S)"
INSTALL_PACKAGES=true
INSTALL_SDDM=true

# Colors for output
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_BLUE="\033[34m"
C_CYAN="\033[36m"
C_YELLOW="\033[33m"
C_RED="\033[31m"

banner() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
    cat << "EOF"
  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   ███████╗██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ╚════██║██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ███████║██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝╚══════╝╚══════╝╚══════╝
EOF
    echo -e "${C_BLUE}           Hyprland + Waybar + SDDM Dynamic Rice Installer${C_RESET}\n"
}

log_info() {
    echo -e "${C_CYAN}::${C_RESET} ${C_BOLD}$1${C_RESET}"
}

log_ok() {
    echo -e "${C_GREEN}✓${C_RESET} ${C_BOLD}$1${C_RESET}"
}

log_warn() {
    echo -e "${C_YELLOW}!${C_RESET} ${C_BOLD}$1${C_RESET}"
}

log_err() {
    echo -e "${C_RED}✗${C_RESET} ${C_BOLD}$1${C_RESET}"
}

# Parse CLI flags
for arg in "$@"; do
    case "$arg" in
        --no-packages|-n)
            INSTALL_PACKAGES=false
            ;;
        --no-sddm)
            INSTALL_SDDM=false
            ;;
        --help|-h)
            echo "Использование: ./install.sh [опции]"
            echo "Опции:"
            echo "  --no-packages, -n   Пропустить установку пакетов (только скопировать конфиги)"
            echo "  --no-sddm           Пропустить настройку темы SDDM"
            echo "  --help, -h          Показать это справочное сообщение"
            exit 0
            ;;
    esac
done

banner

# 1. Package Installation (Arch Linux / pacman / yay)
if [[ "$INSTALL_PACKAGES" == true ]]; then
    if command -v pacman &>/dev/null; then
        log_info "Проверка и установка зависимостей..."
        
        PACKAGES=(
            hyprland
            waybar
            foot
            kitty
            rofi-wayland
            cava
            btop
            fastfetch
            fish
            starship
            python
            python-pillow
            grim
            slurp
            wl-clipboard
            libnotify
            brightnessctl
            sddm
            qt6-5compat
            qt6-declarative
            qt6-svg
            ttf-jetbrains-mono-nerd
        )

        MISSING_PKGS=()
        for pkg in "${PACKAGES[@]}"; do
            if ! pacman -Qi "$pkg" &>/dev/null; then
                MISSING_PKGS+=("$pkg")
            fi
        done

        if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
            log_warn "Требуется установить: ${MISSING_PKGS[*]}"
            read -rp "Установить недостающие пакеты через sudo pacman? [Y/n] " response
            response=${response:-Y}
            if [[ "$response" =~ ^[Yy]$ ]]; then
                sudo pacman -S --needed "${MISSING_PKGS[@]}"
            else
                log_warn "Установка пакетов пропущена пользователем."
            fi
        else
            log_ok "Все основные пакеты pacman уже установлены."
        fi

        # Проверка демона обоев (awww или swww)
        if ! command -v awww &>/dev/null && ! command -v swww &>/dev/null; then
            log_warn "Демон обоев awww / swww не найден."
            if command -v yay &>/dev/null; then
                read -rp "Установить awww из AUR через yay? [Y/n] " aur_resp
                aur_resp=${aur_resp:-Y}
                if [[ "$aur_resp" =~ ^[Yy]$ ]]; then
                    yay -S --needed awww
                fi
            elif command -v paru &>/dev/null; then
                read -rp "Установить awww из AUR через paru? [Y/n] " aur_resp
                aur_resp=${aur_resp:-Y}
                if [[ "$aur_resp" =~ ^[Yy]$ ]]; then
                    paru -S --needed awww
                fi
            else
                log_warn "Установите awww или swww вручную для работы динамических обоев."
            fi
        else
            log_ok "Демон обоев найден: $(command -v awww || command -v swww)"
        fi
    fi
fi

# 2. Backup existing configs
log_info "Создание резервной копии текущих конфигураций..."
mkdir -p "$BACKUP_DIR"
CONFIG_LIST=(hypr waybar foot kitty rofi cava btop fastfetch fish sddm-theme)

BACKED_UP=false
for cfg in "${CONFIG_LIST[@]}"; do
    if [[ -d "$HOME/.config/$cfg" ]]; then
        cp -r "$HOME/.config/$cfg" "$BACKUP_DIR/"
        BACKED_UP=true
    fi
done

if [[ "$BACKED_UP" == true ]]; then
    log_ok "Резервная копия сохранена в: $BACKUP_DIR"
else
    rm -rf "$BACKUP_DIR"
    log_info "Существующих конфигураций для бэкапа не найдено."
fi

# 3. Deploy .config files
log_info "Установка конфигураций в ~/.config/..."
mkdir -p "$HOME/.config"
cp -r "$DOTS_DIR/.config/"* "$HOME/.config/"

# Ensure scripts have execution permissions
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/scripts/"*.py 2>/dev/null || true
chmod +x "$HOME/.config/sddm-theme/"*.sh 2>/dev/null || true
log_ok "Конфигурации успешно скопированы."

# 4. Deploy Wallpapers
log_info "Установка обоев в ~/Pictures/Pixel/..."
mkdir -p "$HOME/Pictures/Pixel"
if [[ -d "$DOTS_DIR/wallpapers" ]]; then
    cp -r "$DOTS_DIR/wallpapers/"* "$HOME/Pictures/Pixel/"
    log_ok "Обои скопированы в ~/Pictures/Pixel/."
fi

# 5. Install SDDM Theme (hypr-sync)
if [[ "$INSTALL_SDDM" == true ]]; then
    echo
    log_info "Настройка темы SDDM (hypr-sync)..."
    read -rp "Установить тему SDDM hypr-sync с правами sudo? [Y/n] " sddm_choice
    sddm_choice=${sddm_choice:-Y}
    if [[ "$sddm_choice" =~ ^[Yy]$ ]]; then
        sudo "$HOME/.config/sddm-theme/install_sddm.sh"
        log_ok "Тема SDDM hypr-sync установлена и активирована."
    else
        log_warn "Установка темы SDDM пропущена. Вы можете запустить её позже: sudo ~/.config/sddm-theme/install_sddm.sh"
    fi
fi

# 6. Initialize Theme & Palettes
log_info "Инициализация обоев и палитры..."
if [[ -x "$HOME/.config/hypr/scripts/wall.sh" ]]; then
    "$HOME/.config/hypr/scripts/wall.sh" --restore 2>/dev/null || "$HOME/.config/hypr/scripts/wall.sh" --random 2>/dev/null || true
    log_ok "Палитра и темы Waybar/Foot/Kitty/Rofi/SDDM инициализированы."
fi

echo
echo -e "${C_GREEN}${C_BOLD}================================================================${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}     Установка завершена успешно! Наслаждайтесь вашим Rice!     ${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}================================================================${C_RESET}"
echo -e "Горячие клавиши:"
echo -e "  • ${C_CYAN}SUPER + RETURN${C_RESET}  - Терминал (Foot)"
echo -e "  • ${C_CYAN}SUPER + R / SUPER${C_RESET} - Меню приложений (Rofi)"
echo -e "  • ${C_CYAN}SUPER + W${C_RESET}        - Случайные обои и авто-палитра"
echo -e "  • ${C_CYAN}SUPER + Q${C_RESET}        - Закрыть окно"
echo -e "  • ${C_CYAN}SUPER + B${C_RESET}        - Браузер"
echo -e "  • ${C_CYAN}SUPER + E${C_RESET}        - Файловый менеджер"
echo -e "  • ${C_CYAN}SUPER + N${C_RESET}        - Музыкальный визуализатор (Cava)"
echo -e "  • ${C_CYAN}SUPER + SHIFT + B${C_RESET}- Монитор ресурсов (Btop)"
echo -e "  • ${C_CYAN}Print / SUPER+SHIFT+S${C_RESET} - Скриншот"
echo

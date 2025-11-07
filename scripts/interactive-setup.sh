#!/bin/bash

# Interactive Keyboard Setup with Key Detection
# User presses the actual keys they want to use

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
REVERSE='\033[7m'
NC='\033[0m'

# Config
CONFIG_FILE="$HOME/.config/hypr/keyboard-hotswap.conf"
HYPR_CONFIG_DIR="$HOME/.config/hypr"

# Clear screen for clean UI
clear

# Beautiful welcome
show_welcome() {
    echo -e "${CYAN}"
    cat << "EOF"

    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║         ⌨️  INTERACTIVE KEYBOARD SETUP               ║
    ║                                                      ║
    ║     Press the actual keys you want to use!          ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"
}

# Show keyboard visual
show_keyboard() {
    echo -e "${DIM}"
    cat << "EOF"
    ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬──────┐
    │Esc│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ - │ = │ Bksp │
    ├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬────┤
    │ Tab │ Q │ W │ E │ R │ T │ Y │ U │ I │ O │ P │ [ │ ] │ \  │
    ├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴────┤
    │ Caps │ A │ S │ D │ F │ G │ H │ J │ K │ L │ ; │ ' │ Enter │
    ├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴───────┤
    │ Shift  │ Z │ X │ C │ V │ B │ N │ M │ , │ . │ / │  Shift  │
    ├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬───┤
    │Ctrl│Alt │Cmd │         Space          │Cmd │Alt │Menu│Ctl│
    └────┴────┴────┴────────────────────────┴────┴────┴────┴───┘
EOF
    echo -e "${NC}"
}

# Detect keyboard
detect_keyboard() {
    echo -e "${DIM}Detecting USB keyboards...${NC}"
    sleep 1

    KEYBOARD_INFO=$(lsusb | grep -i "keyboard" | grep -v "root hub" | head -1)
    if [ -z "$KEYBOARD_INFO" ]; then
        KEYBOARD_INFO=$(lsusb | grep -v "root hub" | grep -v -i "mouse\|webcam\|camera\|hub" | head -1)
    fi

    if [ -z "$KEYBOARD_INFO" ]; then
        echo -e "${YELLOW}⚠  No external USB keyboard detected${NC}"
        echo -e "${DIM}Please connect your keyboard and try again${NC}"
        exit 1
    fi

    KEYBOARD_ID=$(echo "$KEYBOARD_INFO" | grep -oE '[0-9a-f]{4}:[0-9a-f]{4}' | head -1)
    KEYBOARD_NAME=$(echo "$KEYBOARD_INFO" | sed -E 's/.*[0-9a-f]{4}:[0-9a-f]{4} //')

    echo -e "${GREEN}✓${NC} Found: ${BOLD}$KEYBOARD_NAME${NC}\n"
    sleep 1
}

# Interactive key mapping
interactive_key_test() {
    echo -e "${BOLD}Let's configure your external keyboard!${NC}\n"
    show_keyboard

    echo -e "${CYAN}Looking at the keyboard diagram above:${NC}\n"

    # Direct question approach
    echo -e "${YELLOW}Which physical key do you want to use as SUPER?${NC}"
    echo -e "${DIM}(The key for shortcuts like Super+Q, Super+Enter, etc)${NC}\n"

    PS3=$'\nYour choice (1-4): '
    options=(
        "Alt key (next to spacebar)"
        "Cmd/Super/Win key (between Ctrl and Alt)"
        "Keep current - no changes"
        "Both Alt and Cmd swap"
    )

    select choice in "${options[@]}"; do
        case $choice in
            "Alt key (next to spacebar)")
                # User wants Alt to act as Super
                EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "\n${GREEN}✓${NC} Your Alt key will act as Super"
                echo -e "${DIM}   (Alt becomes Super, Super becomes Alt)${NC}"
                break
                ;;
            "Cmd/Super/Win key (between Ctrl and Alt)")
                # User wants Super to stay as Super
                EXTERNAL_OPTIONS=""
                echo -e "\n${GREEN}✓${NC} Your Cmd/Super key will work as Super"
                echo -e "${DIM}   (No changes needed - keys work as labeled)${NC}"
                break
                ;;
            "Keep current - no changes")
                EXTERNAL_OPTIONS=""
                echo -e "\n${GREEN}✓${NC} Keeping current configuration"
                break
                ;;
            "Both Alt and Cmd swap")
                EXTERNAL_OPTIONS="altwin:swap_alt_win"
                echo -e "\n${GREEN}✓${NC} Swapping all Alt ↔ Super keys"
                break
                ;;
            *)
                echo -e "${YELLOW}Please select 1-4${NC}"
                ;;
        esac
    done < /dev/tty
}

# Quick laptop config
laptop_config() {
    echo -e "\n${BOLD}Laptop keyboard configuration${NC}\n"

    echo -e "${CYAN}For your laptop's built-in keyboard:${NC}\n"
    PS3=$'\nYour choice (1-3): '
    options=(
        "Same as external (consistent behavior)"
        "Swap Alt ↔ Super (Mac-style)"
        "Keep default (no changes)"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Same as external (consistent behavior)")
                LAPTOP_OPTIONS="$EXTERNAL_OPTIONS"
                echo -e "${GREEN}✓${NC} Laptop will match external\n"
                break
                ;;
            "Swap Alt ↔ Super (Mac-style)")
                LAPTOP_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "${GREEN}✓${NC} Laptop will use Mac-style\n"
                break
                ;;
            "Keep default (no changes)")
                LAPTOP_OPTIONS=""
                echo -e "${GREEN}✓${NC} Laptop will use default\n"
                break
                ;;
        esac
    done < /dev/tty
}

# Main flow
main() {
    show_welcome

    # Step 1: Detect keyboard
    echo -e "${BOLD}Step 1:${NC} Finding your keyboard\n"
    detect_keyboard

    # Step 2: Interactive key test
    echo -e "${BOLD}Step 2:${NC} Interactive key mapping\n"
    interactive_key_test

    # Step 3: Laptop config
    echo -e "\n${BOLD}Step 3:${NC} Laptop configuration"
    laptop_config

    # Save configuration
    mkdir -p "$HYPR_CONFIG_DIR"

    cat > "$CONFIG_FILE" <<EOF
# Hyprland Keyboard Hotswap Configuration
# Generated on $(date)

# External keyboard: $KEYBOARD_NAME
EXTERNAL_KEYBOARD_ID="$KEYBOARD_ID"
EXTERNAL_KEYBOARD_DESC="$KEYBOARD_NAME"

# Key mappings (automatically detected)
LAPTOP_KB_OPTIONS="$LAPTOP_OPTIONS"
EXTERNAL_KB_OPTIONS="$EXTERNAL_OPTIONS"
EOF

    # Success screen
    clear
    echo -e "${GREEN}"
    cat << "EOF"

    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║              ✅ SETUP COMPLETE!                      ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    echo -e "${BOLD}Configuration Summary:${NC}\n"

    if [ -z "$EXTERNAL_OPTIONS" ]; then
        echo -e "  ${GREEN}●${NC} External keyboard: Keys work as labeled"
    else
        echo -e "  ${GREEN}●${NC} External keyboard: Alt ↔ Super swapped"
    fi

    if [ -z "$LAPTOP_OPTIONS" ]; then
        echo -e "  ${GREEN}●${NC} Laptop keyboard: Keys work as labeled"
    else
        echo -e "  ${GREEN}●${NC} Laptop keyboard: Alt ↔ Super swapped"
    fi

    echo -e "\n${DIM}Auto-switching is now enabled!${NC}\n"

    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
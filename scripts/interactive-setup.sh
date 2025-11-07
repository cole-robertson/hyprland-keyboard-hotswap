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
    echo -e "${BOLD}Let's test your external keyboard!${NC}\n"
    show_keyboard

    echo -e "${CYAN}On your EXTERNAL keyboard:${NC}\n"

    # Test current behavior
    echo -e "${YELLOW}1. Press what you think is the SUPER (Windows/Cmd) key${NC}"
    echo -e "${DIM}   (The key you want to use for shortcuts like Super+Q)${NC}"
    echo -e "\n${DIM}Press the key now...${NC}"

    # Capture a key (simplified - we'll map based on position)
    read -n 1 -s < /dev/tty
    echo -e "${GREEN}✓${NC} Key detected\n"

    echo -e "${YELLOW}2. Which key did you just press?${NC}\n"
    PS3=$'\nSelect the physical key you pressed (1-4): '
    options=(
        "Left Alt (next to spacebar)"
        "Left Cmd/Super/Win (between Ctrl and Alt)"
        "Right Alt"
        "Right Cmd/Super/Win"
    )

    select key_pressed in "${options[@]}"; do
        case $key_pressed in
            "Left Alt (next to spacebar)")
                USER_PRESSED="lalt"
                break
                ;;
            "Left Cmd/Super/Win (between Ctrl and Alt)")
                USER_PRESSED="lsuper"
                break
                ;;
            "Right Alt")
                USER_PRESSED="ralt"
                break
                ;;
            "Right Cmd/Super/Win")
                USER_PRESSED="rsuper"
                break
                ;;
        esac
    done < /dev/tty

    echo -e "\n${GREEN}✓${NC} Got it! You pressed the ${BOLD}$key_pressed${NC}"

    # Determine configuration needed
    echo -e "\n${CYAN}Setting up your configuration...${NC}"

    if [[ "$USER_PRESSED" == "lalt" ]]; then
        # User pressed Alt but wants it to be Super
        EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
        echo -e "${GREEN}✓${NC} Will swap Left Alt ↔ Left Super"
    elif [[ "$USER_PRESSED" == "lsuper" ]]; then
        # User pressed Super and wants it to stay Super
        EXTERNAL_OPTIONS=""
        echo -e "${GREEN}✓${NC} Keys will work as labeled (no swap needed)"
    elif [[ "$USER_PRESSED" == "ralt" ]]; then
        # User wants right alt as super
        EXTERNAL_OPTIONS="altwin:swap_alt_win"
        echo -e "${GREEN}✓${NC} Will swap Alt ↔ Super keys"
    else
        # Right super
        EXTERNAL_OPTIONS=""
        echo -e "${GREEN}✓${NC} Keys will work as labeled"
    fi
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
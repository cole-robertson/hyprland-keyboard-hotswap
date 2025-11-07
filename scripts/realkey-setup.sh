#!/bin/bash

# Real Key Detection Setup - Actually detects keypresses!
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
NC='\033[0m'

# Config
CONFIG_FILE="$HOME/.config/hypr/keyboard-hotswap.conf"
HYPR_CONFIG_DIR="$HOME/.config/hypr"

clear

# Welcome screen
show_welcome() {
    echo -e "${CYAN}"
    cat << "EOF"

    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║        ⌨️  REAL KEY DETECTION SETUP                  ║
    ║                                                      ║
    ║    Actually press the keys you want to use!         ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝

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
        exit 1
    fi

    KEYBOARD_ID=$(echo "$KEYBOARD_INFO" | grep -oE '[0-9a-f]{4}:[0-9a-f]{4}' | head -1)
    KEYBOARD_NAME=$(echo "$KEYBOARD_INFO" | sed -E 's/.*[0-9a-f]{4}:[0-9a-f]{4} //')

    echo -e "${GREEN}✓${NC} Found: ${BOLD}$KEYBOARD_NAME${NC}\n"
}

# Real key detection using bash read
detect_super_key() {
    echo -e "${BOLD}Let's detect your SUPER key!${NC}\n"

    echo -e "${CYAN}Instructions:${NC}"
    echo -e "1. I'll ask you to press a key"
    echo -e "2. Press and HOLD the key for 1 second"
    echo -e "3. Then release it\n"

    echo -e "${YELLOW}Ready? Press ENTER to start...${NC}"
    read -s < /dev/tty

    echo -e "\n${GREEN}NOW: Press and HOLD the key you want as SUPER...${NC}"
    echo -e "${DIM}(The key for Super+Q, Super+Enter, etc)${NC}\n"

    # Detect using timeout and raw input
    echo -e "${YELLOW}Listening for keypress...${NC}"

    # Save terminal state
    OLD_STTY=$(stty -g 2>/dev/null || true)

    # Put terminal in raw mode to capture special keys
    stty -icanon -echo min 0 time 10 2>/dev/null || true

    # Capture the key
    echo -e "${DIM}Press the key NOW...${NC}"
    KEY=""

    # Try to read the key with a visual countdown
    for i in 3 2 1; do
        echo -ne "\r${CYAN}Waiting... $i ${NC}"
        read -t 1 -n 1 KEY_PRESS 2>/dev/null || true
        if [ -n "$KEY_PRESS" ]; then
            KEY="$KEY_PRESS"
            break
        fi
    done

    # Restore terminal
    stty "$OLD_STTY" 2>/dev/null || true

    echo -e "\n"

    # Analyze what was pressed
    if [ -n "$KEY" ]; then
        KEY_CODE=$(printf '%d' "'$KEY" 2>/dev/null || echo "0")
        echo -e "${GREEN}✓${NC} Key detected! (code: $KEY_CODE)"

        # Common key codes
        case $KEY_CODE in
            27|91)
                echo -e "${CYAN}Looks like Alt or a special key${NC}"
                DETECTED_TYPE="alt"
                ;;
            32)
                echo -e "${CYAN}That was Space - let's try again${NC}"
                DETECTED_TYPE="retry"
                ;;
            *)
                echo -e "${CYAN}Got a key signal${NC}"
                DETECTED_TYPE="unknown"
                ;;
        esac
    else
        echo -e "${YELLOW}No key detected - let's use the menu${NC}"
        DETECTED_TYPE="menu"
    fi

    # Confirm what they pressed
    echo -e "\n${BOLD}Which key did you actually press?${NC}\n"
    PS3=$'\nConfirm your key (1-4): '
    options=(
        "Left Alt (beside spacebar)"
        "Left Cmd/Super/Win (between Ctrl and Alt)"
        "Right Alt"
        "I want to choose from a menu instead"
    )

    select choice in "${options[@]}"; do
        case $choice in
            "Left Alt (beside spacebar)")
                EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "\n${GREEN}✓${NC} Alt will become your Super key"
                break
                ;;
            "Left Cmd/Super/Win (between Ctrl and Alt)")
                EXTERNAL_OPTIONS=""
                echo -e "\n${GREEN}✓${NC} Cmd/Super stays as Super (no change)"
                break
                ;;
            "Right Alt")
                EXTERNAL_OPTIONS="altwin:swap_ralt_rwin"
                echo -e "\n${GREEN}✓${NC} Right Alt will become Super"
                break
                ;;
            "I want to choose from a menu instead")
                select_from_menu
                break
                ;;
        esac
    done < /dev/tty
}

# Fallback menu selection
select_from_menu() {
    echo -e "\n${CYAN}Select your preferred key mapping:${NC}\n"
    PS3=$'\nYour choice (1-4): '
    options=(
        "Use Alt as Super (swap them)"
        "Use Cmd/Win as Super (no change)"
        "Swap both Alt and Super keys"
        "No changes"
    )

    select choice in "${options[@]}"; do
        case $choice in
            "Use Alt as Super (swap them)")
                EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                break ;;
            "Use Cmd/Win as Super (no change)")
                EXTERNAL_OPTIONS=""
                break ;;
            "Swap both Alt and Super keys")
                EXTERNAL_OPTIONS="altwin:swap_alt_win"
                break ;;
            "No changes")
                EXTERNAL_OPTIONS=""
                break ;;
        esac
    done < /dev/tty
}

# Laptop config
laptop_config() {
    echo -e "\n${BOLD}Laptop keyboard configuration${NC}\n"
    PS3=$'\nYour choice (1-3): '
    options=(
        "Same as external"
        "Swap Alt ↔ Super (Mac-style)"
        "No changes"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Same as external")
                LAPTOP_OPTIONS="$EXTERNAL_OPTIONS"
                break ;;
            "Swap Alt ↔ Super (Mac-style)")
                LAPTOP_OPTIONS="altwin:swap_lalt_lwin"
                break ;;
            "No changes")
                LAPTOP_OPTIONS=""
                break ;;
        esac
    done < /dev/tty
}

# Main flow
main() {
    show_welcome

    echo -e "${BOLD}Step 1:${NC} Finding your keyboard\n"
    detect_keyboard

    echo -e "${BOLD}Step 2:${NC} Detecting your SUPER key\n"
    detect_super_key

    echo -e "\n${BOLD}Step 3:${NC} Laptop configuration"
    laptop_config

    # Save configuration
    mkdir -p "$HYPR_CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
# Hyprland Keyboard Hotswap Configuration
# External keyboard: $KEYBOARD_NAME
EXTERNAL_KEYBOARD_ID="$KEYBOARD_ID"
EXTERNAL_KEYBOARD_DESC="$KEYBOARD_NAME"
LAPTOP_KB_OPTIONS="$LAPTOP_OPTIONS"
EXTERNAL_KB_OPTIONS="$EXTERNAL_OPTIONS"
EOF

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
    echo -e "${BOLD}Your keyboard is now configured!${NC}\n"

    return 0
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
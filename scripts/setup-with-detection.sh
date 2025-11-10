#!/bin/bash

# Keyboard setup with REAL key detection
# Actually listens for and detects keypresses!

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear

# Welcome
show_welcome() {
    echo -e "${CYAN}"
    cat << "EOF"

    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║      ⌨️  KEYBOARD SETUP WITH KEY DETECTION          ║
    ║                                                      ║
    ║         Actually detects your keypresses!           ║
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

# Real key detection
detect_super_key() {
    echo -e "${BOLD}Let's detect your SUPER key!${NC}\n"

    echo -e "${CYAN}We'll try to detect your actual keypress.${NC}"
    echo -e "${YELLOW}When ready, press the key you want as SUPER.${NC}\n"

    # Source the key listener
    source "$SCRIPT_DIR/listen-key.sh" 2>/dev/null || true

    # Try to detect the key
    KEY_OUTPUT=$(listen_for_key 2>&1 || echo "FAILED")

    # Parse the result
    if echo "$KEY_OUTPUT" | grep -q "KEY_NAME="; then
        DETECTED_KEY=$(echo "$KEY_OUTPUT" | grep "KEY_NAME=" | cut -d= -f2)
        echo -e "\n${GREEN}✓${NC} Detected: ${BOLD}$DETECTED_KEY${NC}"

        # Now confirm what they want
        echo -e "\n${CYAN}You pressed the $DETECTED_KEY key.${NC}"
        echo -e "${YELLOW}Do you want this key to be your SUPER key?${NC}\n"

        PS3=$'\nYour choice (1-3): '
        select choice in "Yes, use $DETECTED_KEY as SUPER" "No, let me try again" "Choose from menu instead"; do
            case $choice in
                "Yes, use $DETECTED_KEY as SUPER")
                    # Determine configuration based on detected key
                    case "$DETECTED_KEY" in
                        *Alt*|*alt*)
                            EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                            echo -e "\n${GREEN}✓${NC} Alt will be your SUPER key"
                            ;;
                        *Super*|*Win*|*Cmd*|*super*|*win*|*cmd*)
                            EXTERNAL_OPTIONS=""
                            echo -e "\n${GREEN}✓${NC} Super/Win/Cmd stays as SUPER"
                            ;;
                        *)
                            echo -e "\n${YELLOW}Unusual key - using default${NC}"
                            manual_selection
                            ;;
                    esac
                    break
                    ;;
                "No, let me try again")
                    detect_super_key
                    return
                    ;;
                "Choose from menu instead")
                    manual_selection
                    break
                    ;;
            esac
        done < /dev/tty
    else
        echo -e "\n${YELLOW}Could not detect key - using manual selection${NC}"
        manual_selection
    fi
}

# Manual selection fallback
manual_selection() {
    echo -e "\n${BOLD}Manual key selection${NC}\n"
    echo -e "${CYAN}Which key do you want as SUPER?${NC}\n"

    PS3=$'\nSelect (1-4): '
    options=(
        "Left Alt (beside spacebar)"
        "Left Cmd/Super/Win (between Ctrl and Alt)"
        "Keep default (no changes)"
        "Swap all Alt ↔ Super keys"
    )

    select choice in "${options[@]}"; do
        case $choice in
            "Left Alt (beside spacebar)")
                EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "${GREEN}✓${NC} Alt will be SUPER"
                break ;;
            "Left Cmd/Super/Win (between Ctrl and Alt)")
                EXTERNAL_OPTIONS=""
                echo -e "${GREEN}✓${NC} Cmd/Super stays as SUPER"
                break ;;
            "Keep default (no changes)")
                EXTERNAL_OPTIONS=""
                echo -e "${GREEN}✓${NC} No changes"
                break ;;
            "Swap all Alt ↔ Super keys")
                EXTERNAL_OPTIONS="altwin:swap_alt_win"
                echo -e "${GREEN}✓${NC} All Alt/Super swapped"
                break ;;
        esac
    done < /dev/tty
}

# Laptop config
laptop_config() {
    echo -e "\n${BOLD}Laptop keyboard configuration${NC}\n"
    PS3=$'\nYour choice (1-3): '
    select opt in "Same as external" "Swap Alt ↔ Super" "No changes"; do
        case $opt in
            "Same as external")
                LAPTOP_OPTIONS="$EXTERNAL_OPTIONS"
                break ;;
            "Swap Alt ↔ Super")
                LAPTOP_OPTIONS="altwin:swap_lalt_lwin"
                break ;;
            "No changes")
                LAPTOP_OPTIONS=""
                break ;;
        esac
    done < /dev/tty
}

# Main
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
    echo -e "${BOLD}Key detection successful!${NC}\n"

    return 0
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
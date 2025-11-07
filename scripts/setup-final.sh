#!/bin/bash

# Hyprland Keyboard Hotswap - Final Simple Setup
# Using bash's built-in select for reliability

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
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
    ║           ⌨️  KEYBOARD SETUP WIZARD                   ║
    ║                                                      ║
    ║      Making your keyboard work exactly how          ║
    ║            you want in 30 seconds                   ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"
}

# Keyboard detection
detect_keyboard() {
    echo -e "${DIM}Detecting USB keyboards...${NC}"
    sleep 1

    # Find keyboard in USB devices
    KEYBOARD_INFO=$(lsusb | grep -i "keyboard" | grep -v "root hub" | head -1)

    if [ -z "$KEYBOARD_INFO" ]; then
        # Try to find any USB HID device that might be a keyboard
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

    # Confirm keyboard
    echo -e "${CYAN}Is this your external keyboard?${NC}"
    PS3="Select (1-2): "
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) echo -e "${GREEN}✓${NC} Keyboard confirmed\n"; break;;
            No ) echo -e "${YELLOW}Please disconnect other USB devices and try again${NC}"; exit 1;;
            * ) echo -e "${YELLOW}Please select 1 or 2${NC}";;
        esac
    done < /dev/tty
}

# Main setup
main() {
    show_welcome

    # Step 1: Detect keyboard
    echo -e "${BOLD}Step 1:${NC} Finding your keyboard\n"
    detect_keyboard

    # Step 2: Configure external keyboard
    echo -e "\n${BOLD}Step 2:${NC} Configure external keyboard"
    echo -e "${CYAN}How should your external keyboard work?${NC}\n"

    PS3=$'\nYour choice (1-4): '
    options=(
        "Keep as is (no changes)"
        "Swap Alt ↔ Super (left side)"
        "Swap Alt ↔ Super (both sides)"
        "Mac style (Cmd→Super)"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Keep as is (no changes)")
                EXTERNAL_OPTIONS=""
                echo -e "${GREEN}✓${NC} External keyboard: default layout\n"
                break
                ;;
            "Swap Alt ↔ Super (left side)")
                EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "${GREEN}✓${NC} External keyboard: left Alt/Super swapped\n"
                break
                ;;
            "Swap Alt ↔ Super (both sides)")
                EXTERNAL_OPTIONS="altwin:swap_alt_win"
                echo -e "${GREEN}✓${NC} External keyboard: all Alt/Super swapped\n"
                break
                ;;
            "Mac style (Cmd→Super)")
                EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "${GREEN}✓${NC} External keyboard: Mac-style layout\n"
                break
                ;;
            *)
                echo -e "${YELLOW}Invalid option, please try again${NC}"
                ;;
        esac
    done < /dev/tty

    # Step 3: Configure laptop keyboard
    echo -e "${BOLD}Step 3:${NC} Configure laptop keyboard"
    echo -e "${CYAN}How should your laptop keyboard work?${NC}\n"

    PS3=$'\nYour choice (1-3): '
    options=(
        "Swap Alt ↔ Super (recommended)"
        "Keep as is (no changes)"
        "Same as external keyboard"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Swap Alt ↔ Super (recommended)")
                LAPTOP_OPTIONS="altwin:swap_lalt_lwin"
                echo -e "${GREEN}✓${NC} Laptop: Mac-style layout\n"
                break
                ;;
            "Keep as is (no changes)")
                LAPTOP_OPTIONS=""
                echo -e "${GREEN}✓${NC} Laptop: default layout\n"
                break
                ;;
            "Same as external keyboard")
                LAPTOP_OPTIONS="$EXTERNAL_OPTIONS"
                echo -e "${GREEN}✓${NC} Laptop: matches external\n"
                break
                ;;
            *)
                echo -e "${YELLOW}Invalid option, please try again${NC}"
                ;;
        esac
    done < /dev/tty

    # Save configuration
    mkdir -p "$HYPR_CONFIG_DIR"

    cat > "$CONFIG_FILE" <<EOF
# Hyprland Keyboard Hotswap Configuration
# Generated on $(date)

# External keyboard: $KEYBOARD_NAME
EXTERNAL_KEYBOARD_ID="$KEYBOARD_ID"
EXTERNAL_KEYBOARD_DESC="$KEYBOARD_NAME"

# Key mappings
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

    echo -e "${BOLD}What happens now:${NC}\n"
    echo -e "  ${GREEN}●${NC} Connect keyboard → External layout"
    echo -e "  ${GREEN}●${NC} Disconnect → Laptop layout"
    echo -e "  ${GREEN}●${NC} Startup → Correct layout loads\n"

    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
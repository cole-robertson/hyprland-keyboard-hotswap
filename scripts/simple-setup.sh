#!/bin/bash

# Hyprland Keyboard Hotswap - Ultra Simple Setup
# Beautiful, minimal UX for keyboard configuration

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

# Simple keyboard detection
detect_keyboard() {
    echo -e "${DIM}Detecting USB keyboards...${NC}"
    sleep 1

    # Get all USB devices and their classes
    # We'll look for HID devices that are likely keyboards (not mice, webcams, etc)
    KEYBOARD_INFO=""

    # First, try to find devices that explicitly mention "keyboard" in any case
    KEYBOARD_INFO=$(lsusb | grep -i "keyboard" | grep -v "root hub" | head -1)

    # If no explicit keyboard found, look for USB HID devices (class 03)
    # Exclude common non-keyboard devices
    if [ -z "$KEYBOARD_INFO" ]; then
        for device in $(lsusb | grep -v "root hub" | grep -v -i "mouse\|webcam\|camera\|hub\|receiver\|wireless.*adapter"); do
            # Check if it looks like it could be a keyboard (has vendor/product ID)
            if echo "$device" | grep -qE "ID [0-9a-f]{4}:[0-9a-f]{4}"; then
                # For now, we'll take the first non-excluded device
                # In practice, this will often be a keyboard
                KEYBOARD_INFO="$device"
                break
            fi
        done
    fi

    if [ -z "$KEYBOARD_INFO" ]; then
        echo -e "${YELLOW}⚠  No external USB keyboard detected${NC}"
        echo -e "${DIM}Please connect your keyboard and try again${NC}"
        echo -e "${DIM}Detected USB devices:${NC}"
        lsusb | grep -v "root hub" | head -5
        exit 1
    fi

    KEYBOARD_ID=$(echo "$KEYBOARD_INFO" | grep -oE '[0-9a-f]{4}:[0-9a-f]{4}' | head -1)
    KEYBOARD_NAME=$(echo "$KEYBOARD_INFO" | sed -E 's/.*[0-9a-f]{4}:[0-9a-f]{4} //')

    echo -e "${GREEN}✓${NC} Found: ${BOLD}$KEYBOARD_NAME${NC}\n"

    # Ask for confirmation
    echo -e "${CYAN}Is this your external keyboard? (y/n)${NC}"
    read -n 1 -r confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Please disconnect other USB devices and try again${NC}"
        exit 1
    fi

    sleep 1
}

# Get key input using read with timeout
get_key_choice() {
    local prompt="$1"
    local current="$2"

    echo -e "${CYAN}$prompt${NC}"
    echo -e "${DIM}Currently: $current${NC}\n"

    echo -e "Choose an option:"
    echo -e "  ${BOLD}1${NC} → Keep as is"
    echo -e "  ${BOLD}2${NC} → Swap Alt ↔ Super (left side)"
    echo -e "  ${BOLD}3${NC} → Swap Alt ↔ Super (both sides)"
    echo -e "  ${BOLD}4${NC} → Mac style (Cmd→Super, Option→Alt)"
    echo ""

    read -p "$(echo -e ${CYAN}Your choice [1-4]: ${NC})" -n 1 choice
    echo ""

    case $choice in
        1) return 1 ;;
        2) echo "altwin:swap_lalt_lwin" ;;
        3) echo "altwin:swap_alt_win" ;;
        4) echo "altwin:swap_lalt_lwin" ;;
        *) return 1 ;;
    esac
}

# Beautiful progress indicator
show_progress() {
    local step=$1
    local total=$2
    local desc=$3

    echo -e "\n${DIM}Step $step of $total${NC}"
    echo -e "${BOLD}$desc${NC}"
    echo ""
}

# Main setup flow
main() {
    show_welcome

    # Step 1: Detect keyboard
    show_progress 1 3 "Finding your keyboard"
    detect_keyboard

    # Step 2: Configure external keyboard
    show_progress 2 3 "External keyboard setup"

    echo -e "${CYAN}How should your ${BOLD}external keyboard${NC}${CYAN} work?${NC}\n"

    EXTERNAL_OPTIONS=$(get_key_choice "External keyboard keys" "Physical keys match labels")
    if [ $? -eq 1 ]; then
        EXTERNAL_OPTIONS=""
        echo -e "${GREEN}✓${NC} Keeping default layout\n"
    else
        echo -e "${GREEN}✓${NC} Layout configured\n"
    fi

    sleep 1

    # Step 3: Configure laptop keyboard
    show_progress 3 3 "Laptop keyboard setup"

    echo -e "${CYAN}How should your ${BOLD}laptop keyboard${NC}${CYAN} work?${NC}\n"

    LAPTOP_OPTIONS=$(get_key_choice "Laptop keyboard keys" "Physical keys match labels")
    if [ $? -eq 1 ]; then
        LAPTOP_OPTIONS="altwin:swap_lalt_lwin"  # Default to swapped for laptop
        echo -e "${GREEN}✓${NC} Using Mac-style layout (Alt ↔ Super swapped)\n"
    else
        echo -e "${GREEN}✓${NC} Layout configured\n"
    fi

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
    echo -e "  ${GREEN}●${NC} When you ${BOLD}connect${NC} your keyboard → External layout active"
    echo -e "  ${GREEN}●${NC} When you ${BOLD}disconnect${NC} it → Laptop layout active"
    echo -e "  ${GREEN}●${NC} On ${BOLD}startup${NC} → Correct layout loads automatically\n"

    echo -e "${DIM}Configuration saved to: $CONFIG_FILE${NC}\n"

    # Return success for installer to continue
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
#!/bin/bash

# Hyprland Keyboard Hotswap - Ultra Simple Setup with Arrow Navigation
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
REVERSE='\033[7m'
NC='\033[0m'

# Config
CONFIG_FILE="$HOME/.config/hypr/keyboard-hotswap.conf"
HYPR_CONFIG_DIR="$HOME/.config/hypr"

# Source the arrow menu function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/arrow-menu.sh"

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
    echo -e "${DIM}Use ↑/↓ arrows to navigate, Enter to select${NC}\n"
}

# Simple keyboard detection
detect_keyboard() {
    echo -e "${DIM}Detecting USB keyboards...${NC}"
    sleep 1

    # Get all USB devices
    KEYBOARD_INFO=""

    # First, try to find devices that explicitly mention "keyboard"
    KEYBOARD_INFO=$(lsusb | grep -i "keyboard" | grep -v "root hub" | head -1)

    # If no explicit keyboard found, look for other USB devices
    if [ -z "$KEYBOARD_INFO" ]; then
        # Get non-hub, non-mouse, non-webcam devices
        for line in $(lsusb | grep -v "root hub" | grep -v -i "mouse\|webcam\|camera\|hub\|receiver"); do
            KEYBOARD_INFO="$line"
            break
        done
    fi

    if [ -z "$KEYBOARD_INFO" ]; then
        echo -e "${YELLOW}⚠  No external USB keyboard detected${NC}"
        echo -e "${DIM}Please connect your keyboard and try again${NC}"
        exit 1
    fi

    KEYBOARD_ID=$(echo "$KEYBOARD_INFO" | grep -oE '[0-9a-f]{4}:[0-9a-f]{4}' | head -1)
    KEYBOARD_NAME=$(echo "$KEYBOARD_INFO" | sed -E 's/.*[0-9a-f]{4}:[0-9a-f]{4} //')

    echo -e "${GREEN}✓${NC} Found: ${BOLD}$KEYBOARD_NAME${NC}\n"

    # Ask for confirmation with arrow menu
    local confirm=$(select_option "Is this your external keyboard?" "Yes, this is my keyboard" "No, try again")

    if [[ "$confirm" != "Yes, this is my keyboard" ]]; then
        echo -e "\n${YELLOW}Please disconnect other USB devices and try again${NC}"
        exit 1
    fi

    echo -e "\n${GREEN}✓${NC} Keyboard confirmed\n"
    sleep 1
}

# Beautiful progress indicator
show_progress() {
    local step=$1
    local total=$2
    local desc=$3

    echo -e "${DIM}Step $step of $total${NC}"
    echo -e "${BOLD}$desc${NC}\n"
}

# Main setup flow
main() {
    show_welcome

    # Step 1: Detect keyboard
    show_progress 1 3 "Finding your keyboard"
    detect_keyboard

    # Step 2: Configure external keyboard
    clear
    show_welcome
    show_progress 2 3 "Configure external keyboard"

    echo -e "${CYAN}How should your ${BOLD}external keyboard${NC}${CYAN} work?${NC}\n"

    EXTERNAL_CHOICE=$(select_option "Select layout for external keyboard:" \
        "Keep as is (no changes)" \
        "Swap Alt ↔ Super (left side only)" \
        "Swap Alt ↔ Super (both sides)" \
        "Mac style (Cmd→Super, Option→Alt)")

    case "$EXTERNAL_CHOICE" in
        "Keep as is (no changes)")
            EXTERNAL_OPTIONS=""
            echo -e "\n${GREEN}✓${NC} External keyboard will use default layout\n"
            ;;
        "Swap Alt ↔ Super (left side only)")
            EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
            echo -e "\n${GREEN}✓${NC} Left Alt and Super will be swapped\n"
            ;;
        "Swap Alt ↔ Super (both sides)")
            EXTERNAL_OPTIONS="altwin:swap_alt_win"
            echo -e "\n${GREEN}✓${NC} All Alt and Super keys will be swapped\n"
            ;;
        "Mac style (Cmd→Super, Option→Alt)")
            EXTERNAL_OPTIONS="altwin:swap_lalt_lwin"
            echo -e "\n${GREEN}✓${NC} Mac-style layout configured\n"
            ;;
    esac

    sleep 1

    # Step 3: Configure laptop keyboard
    clear
    show_welcome
    show_progress 3 3 "Configure laptop keyboard"

    echo -e "${CYAN}How should your ${BOLD}laptop keyboard${NC}${CYAN} work?${NC}\n"

    LAPTOP_CHOICE=$(select_option "Select layout for laptop keyboard:" \
        "Mac style - Swap Alt ↔ Super (recommended)" \
        "Keep as is (no changes)" \
        "Same as external keyboard")

    case "$LAPTOP_CHOICE" in
        "Mac style - Swap Alt ↔ Super (recommended)")
            LAPTOP_OPTIONS="altwin:swap_lalt_lwin"
            echo -e "\n${GREEN}✓${NC} Laptop will use Mac-style layout\n"
            ;;
        "Keep as is (no changes)")
            LAPTOP_OPTIONS=""
            echo -e "\n${GREEN}✓${NC} Laptop will use default layout\n"
            ;;
        "Same as external keyboard")
            LAPTOP_OPTIONS="$EXTERNAL_OPTIONS"
            echo -e "\n${GREEN}✓${NC} Laptop will match external keyboard\n"
            ;;
    esac

    sleep 1

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
#!/bin/bash

# Real key detection for keyboard setup
# Detects actual keypresses and identifies them

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Detect a keypress and identify it
detect_key() {
    local key_detected=""

    echo -e "${CYAN}Press and release the key you want as SUPER:${NC}"
    echo -e "${DIM}(Press it once and let go)${NC}\n"

    # Method 1: Try reading raw keyboard input
    if command -v showkey &> /dev/null; then
        echo -e "${DIM}Using showkey for detection...${NC}"
        echo -e "${YELLOW}Press your desired SUPER key now...${NC}"

        # Run showkey with timeout
        timeout 3 showkey -a 2>/dev/null | head -1 > /tmp/keypress.tmp || true

        if [ -s /tmp/keypress.tmp ]; then
            key_detected=$(cat /tmp/keypress.tmp)
            echo -e "${GREEN}✓${NC} Key detected!"
            return 0
        fi
    fi

    # Method 2: Use terminal raw mode to capture key
    echo -e "${DIM}Reading key in raw mode...${NC}"
    echo -e "${YELLOW}Press your desired SUPER key now:${NC}"

    # Save terminal settings
    OLD_STTY=$(stty -g)

    # Set terminal to raw mode
    stty raw -echo

    # Read one character
    KEY_CHAR=$(dd bs=1 count=1 2>/dev/null)
    KEY_CODE=$(printf '%d' "'$KEY_CHAR")

    # Restore terminal settings
    stty "$OLD_STTY"

    echo -e "\n${GREEN}✓${NC} Key captured!"

    # Identify the key based on common codes
    case $KEY_CODE in
        27)  # ESC or Alt
            echo -e "${CYAN}Detected: Alt or Escape key${NC}"
            key_detected="alt"
            ;;
        91|133)  # Common Super/Win key codes
            echo -e "${CYAN}Detected: Super/Windows key${NC}"
            key_detected="super"
            ;;
        *)
            echo -e "${CYAN}Key code: $KEY_CODE${NC}"
            # Ask user to identify
            echo -e "\n${YELLOW}Which key did you press?${NC}"
            PS3="Select (1-3): "
            select key_type in "Alt key" "Super/Cmd/Win key" "Other"; do
                case $key_type in
                    "Alt key") key_detected="alt"; break ;;
                    "Super/Cmd/Win key") key_detected="super"; break ;;
                    "Other") key_detected="other"; break ;;
                esac
            done < /dev/tty
            ;;
    esac

    # Return the detected key
    echo "$key_detected"
}

# Method 3: Use evtest if available (requires sudo)
detect_with_evtest() {
    if ! command -v evtest &> /dev/null; then
        return 1
    fi

    echo -e "${YELLOW}Detecting keyboard device...${NC}"

    # Find keyboard device
    KEYBOARD_DEVICE=$(find /dev/input/by-id -name "*kbd*" 2>/dev/null | head -1)

    if [ -z "$KEYBOARD_DEVICE" ]; then
        KEYBOARD_DEVICE=$(find /dev/input/by-id -name "*keyboard*" 2>/dev/null | head -1)
    fi

    if [ -n "$KEYBOARD_DEVICE" ]; then
        echo -e "${GREEN}Found keyboard: $KEYBOARD_DEVICE${NC}"
        echo -e "${YELLOW}This requires sudo access for key detection${NC}"

        # Try to use evtest
        sudo timeout 3 evtest "$KEYBOARD_DEVICE" 2>/dev/null | grep -m1 "KEY_" | sed 's/.*KEY_//' | head -1
    else
        return 1
    fi
}

# Main detection function
main() {
    echo -e "${BOLD}Keyboard Key Detection${NC}\n"

    # Try different detection methods
    DETECTED_KEY=$(detect_key)

    echo -e "\n${GREEN}Detection complete!${NC}"
    echo -e "Detected key type: ${BOLD}$DETECTED_KEY${NC}"

    # Configure based on detection
    if [ "$DETECTED_KEY" = "alt" ]; then
        echo -e "\n${CYAN}Configuration:${NC} Swap Alt ↔ Super"
        echo "altwin:swap_lalt_lwin"
    elif [ "$DETECTED_KEY" = "super" ]; then
        echo -e "\n${CYAN}Configuration:${NC} Keep as is (no swap needed)"
        echo ""
    else
        echo -e "\n${YELLOW}Could not determine key mapping${NC}"
    fi
}

# Export for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f detect_key
else
    main "$@"
fi
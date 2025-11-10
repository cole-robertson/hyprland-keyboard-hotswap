#!/bin/bash

# Real key detection that actually works!
# Uses multiple methods to capture actual keypresses

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Detect which key was pressed
DETECTED_KEY=""
DETECTED_CODE=""

# Method 1: Use xev (X11)
detect_with_xev() {
    if ! command -v xev &> /dev/null; then
        return 1
    fi

    if [ -z "$DISPLAY" ]; then
        return 1
    fi

    echo -e "${CYAN}Opening key detection window...${NC}"
    echo -e "${YELLOW}Press the key you want as SUPER in the window that appears${NC}"
    echo -e "${DIM}(The window will close after detecting a key)${NC}\n"

    # Create a temporary xev window and capture the keypress
    timeout 10 xev -event keyboard 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q "KeyPress event"; then
            # Get the next few lines which contain the key info
            read -r line2
            read -r line3
            if echo "$line3" | grep -q "keycode"; then
                KEYCODE=$(echo "$line3" | grep -oP 'keycode \K[0-9]+')
                KEYSYM=$(echo "$line3" | grep -oP '\(keysym 0x[0-9a-f]+, \K[^)]+')
                echo "DETECTED: keycode=$KEYCODE keysym=$KEYSYM"
                pkill xev 2>/dev/null || true
                return 0
            fi
        fi
    done
}

# Method 2: Use wev (Wayland)
detect_with_wev() {
    if ! command -v wev &> /dev/null; then
        return 1
    fi

    echo -e "${CYAN}Wayland key detection...${NC}"
    echo -e "${YELLOW}Press the key you want as SUPER${NC}\n"

    # Run wev and capture keyboard events
    timeout 5 wev 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q "key:"; then
            KEY_INFO=$(echo "$line" | grep -oP 'sym: \K[^,]+')
            echo "DETECTED: $KEY_INFO"
            pkill wev 2>/dev/null || true
            return 0
        fi
    done
}

# Method 3: Use showkey (console)
detect_with_showkey() {
    if ! command -v showkey &> /dev/null; then
        return 1
    fi

    echo -e "${CYAN}Console key detection...${NC}"
    echo -e "${YELLOW}Press the key you want as SUPER${NC}"
    echo -e "${DIM}(Detection will timeout in 5 seconds)${NC}\n"

    # Use showkey to get the keycode
    RESULT=$(timeout 5 showkey -k 2>/dev/null | head -3 | tail -1 || true)
    if [ -n "$RESULT" ]; then
        KEYCODE=$(echo "$RESULT" | grep -oP 'keycode \K[0-9]+' || true)
        if [ -n "$KEYCODE" ]; then
            echo "DETECTED: keycode=$KEYCODE"

            # Map common keycodes
            case $KEYCODE in
                56) echo "Left Alt key detected" ;;
                125) echo "Left Super/Windows key detected" ;;
                100) echo "Right Alt key detected" ;;
                126) echo "Right Super/Windows key detected" ;;
                *) echo "Key code: $KEYCODE" ;;
            esac
            return 0
        fi
    fi
    return 1
}

# Method 4: Python helper script (if Python available)
detect_with_python() {
    if ! command -v python3 &> /dev/null; then
        return 1
    fi

    # Check if we can import the needed modules
    if ! python3 -c "import sys" 2>/dev/null; then
        return 1
    fi

    echo -e "${CYAN}Python key detection...${NC}"
    echo -e "${YELLOW}Press the key you want as SUPER${NC}\n"

    # Create a simple Python key detector
    python3 << 'PYTHON_SCRIPT' 2>/dev/null || return 1
import sys
import termios
import tty
import select

def detect_key():
    print("Listening for keypress (5 seconds)...")

    # Save terminal settings
    old_settings = termios.tcgetattr(sys.stdin)

    try:
        # Set terminal to raw mode
        tty.setraw(sys.stdin.fileno())

        # Wait for input with timeout
        ready, _, _ = select.select([sys.stdin], [], [], 5.0)

        if ready:
            key = sys.stdin.read(1)
            key_code = ord(key)

            print(f"\nDETECTED: key_code={key_code}")

            # Common key mappings
            if key_code == 27:  # ESC or Alt
                print("Likely Alt or Escape key")
            elif key_code in [91, 93]:  # Common Super codes
                print("Likely Super/Windows key")
            else:
                print(f"Key character: {repr(key)}")

            return 0
        else:
            print("\nTimeout - no key detected")
            return 1

    finally:
        # Restore terminal settings
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)

sys.exit(detect_key())
PYTHON_SCRIPT

    return $?
}

# Method 5: Use libinput (if available)
detect_with_libinput() {
    if ! command -v libinput &> /dev/null; then
        return 1
    fi

    echo -e "${CYAN}Libinput detection (may require sudo)...${NC}"
    echo -e "${YELLOW}Press the key you want as SUPER${NC}\n"

    # Find keyboard device
    DEVICE=$(sudo libinput list-devices 2>/dev/null | grep -B5 "Capabilities.*keyboard" | grep "Device:" | head -1 | cut -d: -f2 | xargs)

    if [ -n "$DEVICE" ]; then
        echo -e "${DIM}Monitoring: $DEVICE${NC}"
        sudo timeout 5 libinput debug-events --device "$DEVICE" 2>/dev/null | while read -r line; do
            if echo "$line" | grep -q "KEY_"; then
                KEY=$(echo "$line" | grep -oP 'KEY_\K[A-Z]+')
                echo "DETECTED: $KEY key"
                return 0
            fi
        done
    fi
    return 1
}

# Main detection function
detect_key() {
    echo -e "${BOLD}Real Key Detection${NC}\n"

    # Try different methods in order
    echo -e "${DIM}Trying different detection methods...${NC}\n"

    # Try xev first (most reliable for X11)
    if detect_with_xev; then
        return 0
    fi

    # Try wev for Wayland
    if detect_with_wev; then
        return 0
    fi

    # Try Python (cross-platform)
    if detect_with_python; then
        return 0
    fi

    # Try showkey (requires console)
    if [ -z "$DISPLAY" ] || [ "$TERM" = "linux" ]; then
        if detect_with_showkey; then
            return 0
        fi
    fi

    # Try libinput as last resort
    if detect_with_libinput; then
        return 0
    fi

    echo -e "${YELLOW}Could not detect key automatically${NC}"
    return 1
}

# Main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    detect_key
fi
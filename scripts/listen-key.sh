#!/bin/bash

# Simple key listener that actually works
# Uses available tools to detect keypresses

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Result variables
KEY_DETECTED=""
KEY_NAME=""

# Simple Python key listener (most reliable)
listen_with_python() {
    if ! command -v python3 &> /dev/null; then
        return 1
    fi

    python3 << 'EOF' 2>/dev/null
import os
import sys
import time

print("\033[1;33mPress any key... (waiting 5 seconds)\033[0m")
print("\033[2m(Press the key you want as SUPER)\033[0m\n")

# For Linux, try to read from stdin in raw mode
if sys.platform.startswith('linux'):
    import termios, tty

    # Save current terminal settings
    old_settings = termios.tcgetattr(sys.stdin)

    try:
        # Set terminal to raw mode
        tty.setraw(sys.stdin.fileno())

        # Set non-blocking with timeout
        import select
        ready = select.select([sys.stdin], [], [], 5.0)[0]

        if ready:
            # Read the key
            key = sys.stdin.read(1)

            # Restore terminal first
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)

            # Analyze the key
            key_code = ord(key)
            print(f"\n\033[0;32m✓\033[0m Key detected! (code: {key_code})")

            # Identify common keys
            if key_code == 27:
                print("KEY_NAME=Alt")
            elif key_code == 32:
                print("KEY_NAME=Space")
            elif 97 <= key_code <= 122:
                print(f"KEY_NAME={chr(key_code).upper()}")
            elif key_code < 32:
                print("KEY_NAME=Control_Key")
            else:
                print(f"KEY_NAME=Unknown_{key_code}")

            sys.exit(0)
        else:
            # Restore terminal
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)
            print("\nNo key detected")
            sys.exit(1)

    except Exception as e:
        # Make sure to restore terminal
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)
        print(f"\nError: {e}")
        sys.exit(1)
else:
    print("Platform not supported")
    sys.exit(1)
EOF

    return $?
}

# Use xev to detect key in X11
listen_with_xev() {
    if ! command -v xev &> /dev/null || [ -z "$DISPLAY" ]; then
        return 1
    fi

    echo -e "${YELLOW}A small window will open - click it and press your desired key${NC}"
    echo -e "${DIM}The window will close automatically after detecting the key${NC}\n"

    # Run xev and capture one keypress
    (
        xev -geometry 200x100 -name "Press your SUPER key" 2>/dev/null &
        XEV_PID=$!

        # Monitor xev output
        sleep 0.5
        xdotool search --name "Press your SUPER key" windowfocus 2>/dev/null || true

        timeout 10 stdbuf -oL xev -id $(xdotool search --name "Press your SUPER key" 2>/dev/null | head -1) 2>/dev/null | while IFS= read -r line; do
            if [[ "$line" == *"KeyPress event"* ]]; then
                # Read the next lines to get key info
                read -r line2
                read -r line3
                if [[ "$line3" == *"keycode"* ]]; then
                    KEYCODE=$(echo "$line3" | grep -oP 'keycode \K[0-9]+')
                    KEYSYM=$(echo "$line3" | grep -oP '\(keysym [^,]+, \K[^)]+' || echo "unknown")

                    echo -e "\n${GREEN}✓${NC} Key detected!"
                    echo "KEY_NAME=$KEYSYM"

                    # Kill xev
                    kill $XEV_PID 2>/dev/null || true
                    exit 0
                fi
            fi
        done
    ) || return 1
}

# Use read with timeout (simplest method)
listen_with_read() {
    echo -e "${YELLOW}Press the key you want as SUPER...${NC}"
    echo -e "${DIM}You have 5 seconds${NC}\n"

    # Save terminal settings
    OLD_STTY=$(stty -g 2>/dev/null || echo "")

    # Set terminal to read single character
    stty -icanon -echo time 50 2>/dev/null || true

    # Read with timeout
    KEY=""
    read -t 5 -n 1 KEY 2>/dev/null || true

    # Restore terminal
    [ -n "$OLD_STTY" ] && stty "$OLD_STTY" 2>/dev/null || true

    if [ -n "$KEY" ]; then
        echo -e "\n${GREEN}✓${NC} Key received!"

        # Try to identify the key
        KEY_CODE=$(printf '%d' "'$KEY" 2>/dev/null || echo "0")

        case $KEY_CODE in
            27) echo "KEY_NAME=Alt_or_Escape" ;;
            32) echo "KEY_NAME=Space" ;;
            9) echo "KEY_NAME=Tab" ;;
            *)
                if [ $KEY_CODE -ge 97 ] && [ $KEY_CODE -le 122 ]; then
                    echo "KEY_NAME=$(echo $KEY | tr '[:lower:]' '[:upper:]')"
                else
                    echo "KEY_NAME=Key_$KEY_CODE"
                fi
                ;;
        esac
        return 0
    else
        echo -e "\n${YELLOW}No key detected${NC}"
        return 1
    fi
}

# Main function to try all methods
listen_for_key() {
    echo -e "${BOLD}Listening for your keypress...${NC}\n"

    # Try Python first (most reliable)
    if listen_with_python; then
        return 0
    fi

    # Try xev if in X11
    if [ -n "$DISPLAY" ]; then
        if listen_with_xev; then
            return 0
        fi
    fi

    # Fall back to basic read
    if listen_with_read; then
        return 0
    fi

    echo -e "${RED}Could not detect key${NC}"
    return 1
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    listen_for_key
fi
#!/bin/bash

# Interactive keyboard detection and configuration script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Function to detect USB keyboards
detect_keyboards() {
    print_msg "\nDetecting keyboards..." "$YELLOW"

    # Get all USB keyboards
    mapfile -t USB_KEYBOARDS < <(lsusb | grep -iE "keyboard|keychron|ducky|corsair|razer|logitech|das|hhkb|realforce|leopold|varmilo|anne|akko|royal|filco" | grep -v "root hub")

    # Also check for generic HID keyboards
    if [ ${#USB_KEYBOARDS[@]} -eq 0 ]; then
        mapfile -t USB_KEYBOARDS < <(
            for device in /sys/bus/usb/devices/*/product; do
                if [ -f "$device" ]; then
                    product=$(cat "$device")
                    bus_id=$(basename $(dirname "$device"))
                    vendor_id=$(cat "$(dirname "$device")/idVendor" 2>/dev/null || echo "")
                    product_id=$(cat "$(dirname "$device")/idProduct" 2>/dev/null || echo "")
                    if [[ ! -z "$vendor_id" && ! -z "$product_id" ]]; then
                        # Skip common non-keyboard devices
                        if [[ "$product" =~ [Kk]eyboard ]] || \
                           [[ "$product" =~ [Kk]eychron ]] || \
                           [[ "$product" =~ [Mm]echanical ]] || \
                           [[ "$product" =~ "KB" ]] || \
                           [[ "$product" =~ "HID" ]]; then
                            lsusb | grep -i "${vendor_id}:${product_id}" || true
                        fi
                    fi
                fi
            done | sort -u
        )
    fi

    if [ ${#USB_KEYBOARDS[@]} -eq 0 ]; then
        print_msg "No external USB keyboards detected." "$RED"
        return 1
    fi

    print_msg "\nFound the following USB keyboards:" "$GREEN"
    local i=1
    for kb in "${USB_KEYBOARDS[@]}"; do
        if [ ! -z "$kb" ]; then
            echo "  $i) $kb"
            ((i++))
        fi
    done

    return 0
}

# Function to extract USB ID from lsusb output
extract_usb_id() {
    local line="$1"
    echo "$line" | grep -oE '[0-9a-f]{4}:[0-9a-f]{4}' | head -1
}

# Function to select keyboard
select_keyboard() {
    local num_keyboards=${#USB_KEYBOARDS[@]}

    if [ $num_keyboards -eq 0 ]; then
        return 1
    elif [ $num_keyboards -eq 1 ]; then
        print_msg "\nUsing the only detected keyboard:" "$GREEN"
        echo "  ${USB_KEYBOARDS[0]}"
        SELECTED_KEYBOARD="${USB_KEYBOARDS[0]}"
        SELECTED_USB_ID=$(extract_usb_id "$SELECTED_KEYBOARD")
        return 0
    else
        print_msg "\nMultiple keyboards detected. Please select your external keyboard:" "$YELLOW"
        local i=1
        for kb in "${USB_KEYBOARDS[@]}"; do
            if [ ! -z "$kb" ]; then
                echo "  $i) $kb"
                ((i++))
            fi
        done

        read -p "Enter number (1-$num_keyboards): " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le $num_keyboards ]; then
            SELECTED_KEYBOARD="${USB_KEYBOARDS[$((selection-1))]}"
            SELECTED_USB_ID=$(extract_usb_id "$SELECTED_KEYBOARD")
            print_msg "\nSelected: $SELECTED_KEYBOARD" "$GREEN"
            print_msg "USB ID: $SELECTED_USB_ID" "$BLUE"
            return 0
        else
            print_msg "Invalid selection" "$RED"
            return 1
        fi
    fi
}

# Function to test current key mapping
test_key_mapping() {
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║           KEY MAPPING TEST                    ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    print_msg "\nLet's test your current keyboard setup." "$YELLOW"
    print_msg "When ready, try pressing these keys on your EXTERNAL keyboard:" "$YELLOW"
    print_msg "\n  1. Press what you WANT to be the SUPER (Windows/Cmd) key" "$BLUE"
    print_msg "  2. Press what you WANT to be the ALT key" "$BLUE"
    print_msg "  3. Press what you WANT to be the CTRL key" "$BLUE"

    print_msg "\nNote which physical keys you pressed and how they currently behave." "$YELLOW"
    read -p "Press Enter when you're done testing..."
}

# Function to select key mapping
select_key_mapping() {
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║          CHOOSE KEY MAPPING                   ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    print_msg "\nCommon keyboard layouts:" "$YELLOW"
    print_msg "\n  Windows/Linux keyboard:" "$BLUE"
    print_msg "    [Ctrl] [Super] [Alt] [Space] [Alt] [Menu] [Ctrl]" "$NC"

    print_msg "\n  Mac keyboard:" "$BLUE"
    print_msg "    [Ctrl] [Alt] [Cmd] [Space] [Cmd] [Alt]" "$NC"

    print_msg "\nSelect how you want your EXTERNAL keyboard to work:" "$GREEN"
    echo ""
    echo "  1) Keep default (no changes)"
    echo "  2) Swap Alt ↔ Super (left side only)"
    echo "  3) Swap Alt ↔ Super (both sides)"
    echo "  4) Mac-style: Cmd acts as Super, Option as Alt"
    echo "  5) Custom mapping (advanced)"
    echo ""

    read -p "Enter your choice (1-5): " choice

    case $choice in
        1)
            EXTERNAL_KB_OPTIONS=""
            print_msg "\nNo remapping - keys work as labeled" "$GREEN"
            ;;
        2)
            EXTERNAL_KB_OPTIONS="altwin:swap_lalt_lwin"
            print_msg "\nLeft Alt ↔ Left Super will be swapped" "$GREEN"
            ;;
        3)
            EXTERNAL_KB_OPTIONS="altwin:swap_alt_win"
            print_msg "\nAll Alt ↔ Super keys will be swapped" "$GREEN"
            ;;
        4)
            EXTERNAL_KB_OPTIONS="altwin:swap_lalt_lwin,altwin:swap_ralt_rwin"
            print_msg "\nMac-style: Cmd→Super, Option→Alt" "$GREEN"
            ;;
        5)
            print_msg "\nAdvanced options:" "$YELLOW"
            echo "  altwin:swap_lalt_lwin  - Swap left Alt ↔ Super"
            echo "  altwin:swap_alt_win    - Swap all Alt ↔ Super"
            echo "  altwin:alt_win         - Alt acts as Super"
            echo "  altwin:ctrl_win        - Ctrl acts as Super"
            echo "  caps:swapescape        - Swap Caps Lock ↔ Escape"
            echo "  caps:ctrl_modifier    - Caps Lock acts as Ctrl"
            echo ""
            read -p "Enter kb_options (comma-separated): " EXTERNAL_KB_OPTIONS
            print_msg "\nCustom mapping: $EXTERNAL_KB_OPTIONS" "$GREEN"
            ;;
        *)
            print_msg "Invalid choice, using default" "$RED"
            EXTERNAL_KB_OPTIONS=""
            ;;
    esac
}

# Function to save configuration
save_configuration() {
    local config_file="$HOME/.config/hypr/keyboard-hotswap.conf"

    print_msg "\nSaving configuration..." "$YELLOW"

    cat > "$config_file" <<EOF
# Hyprland Keyboard Hotswap Configuration
# Generated on $(date)

# External keyboard USB ID
EXTERNAL_KEYBOARD_ID="$SELECTED_USB_ID"

# External keyboard description
EXTERNAL_KEYBOARD_DESC="$SELECTED_KEYBOARD"

# Laptop keyboard options (when external is disconnected)
LAPTOP_KB_OPTIONS="${LAPTOP_KB_OPTIONS:-altwin:swap_lalt_lwin}"

# External keyboard options (when external is connected)
EXTERNAL_KB_OPTIONS="${EXTERNAL_KB_OPTIONS}"
EOF

    print_msg "Configuration saved to $config_file" "$GREEN"
}

# Main function
main() {
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║    INTERACTIVE KEYBOARD CONFIGURATION         ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    # Detect keyboards
    if ! detect_keyboards; then
        print_msg "\nPlease connect your external keyboard and run this script again." "$YELLOW"
        exit 1
    fi

    # Select keyboard
    if ! select_keyboard; then
        print_msg "Keyboard selection failed" "$RED"
        exit 1
    fi

    # Test current mapping
    test_key_mapping

    # Select desired mapping
    select_key_mapping

    # Ask about laptop keyboard config
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║        LAPTOP KEYBOARD CONFIGURATION          ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    print_msg "\nHow should your LAPTOP's built-in keyboard work?" "$YELLOW"
    echo ""
    echo "  1) Swap Alt ↔ Super (recommended for Mac-like experience)"
    echo "  2) Keep default (no changes)"
    echo "  3) Same as external keyboard"
    echo ""

    read -p "Enter your choice (1-3): " laptop_choice

    case $laptop_choice in
        1)
            LAPTOP_KB_OPTIONS="altwin:swap_lalt_lwin"
            print_msg "\nLaptop keyboard: Alt ↔ Super swapped" "$GREEN"
            ;;
        2)
            LAPTOP_KB_OPTIONS=""
            print_msg "\nLaptop keyboard: No remapping" "$GREEN"
            ;;
        3)
            LAPTOP_KB_OPTIONS="$EXTERNAL_KB_OPTIONS"
            print_msg "\nLaptop keyboard: Same as external" "$GREEN"
            ;;
        *)
            LAPTOP_KB_OPTIONS="altwin:swap_lalt_lwin"
            print_msg "\nUsing default: Alt ↔ Super swapped" "$YELLOW"
            ;;
    esac

    # Save configuration
    save_configuration

    print_msg "\n✓ Configuration complete!" "$GREEN"
    print_msg "\nYour settings:" "$YELLOW"
    print_msg "  External keyboard: $SELECTED_KEYBOARD" "$NC"
    print_msg "  External mapping: ${EXTERNAL_KB_OPTIONS:-No remapping}" "$NC"
    print_msg "  Laptop mapping: ${LAPTOP_KB_OPTIONS:-No remapping}" "$NC"

    print_msg "\nRun './install.sh' to apply these settings" "$GREEN"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
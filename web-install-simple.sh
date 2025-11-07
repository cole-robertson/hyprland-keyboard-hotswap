#!/bin/bash

# Hyprland Keyboard Hotswap - Minimal Web Installer
# Beautiful one-line installation experience

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Configuration
REPO="cole-robertson/hyprland-keyboard-hotswap"
BRANCH="master"
GITHUB_RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
HYPR_CONFIG_DIR="$HOME/.config/hypr"
TEMP_DIR="/tmp/keyboard-setup-$$"

# Cleanup on exit
cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check dependencies
check_deps() {
    for cmd in curl hyprctl; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: $cmd is required but not installed${NC}"
            exit 1
        fi
    done
}

# Download a file from GitHub
download() {
    local file="$1"
    local dest="$2"

    if ! curl -fsSL "${GITHUB_RAW}/${file}" -o "$dest" 2>/dev/null; then
        echo -e "${RED}Failed to download $file${NC}"
        echo -e "${YELLOW}This might be due to GitHub caching. Try again in a minute, or use:${NC}"
        echo -e "${CYAN}git clone https://github.com/${REPO}.git && cd hyprland-keyboard-hotswap && ./install-simple.sh${NC}"
        exit 1
    fi

    # Verify file was actually downloaded and has content
    if [ ! -f "$dest" ] || [ ! -s "$dest" ]; then
        echo -e "${RED}Downloaded file is empty or missing: $dest${NC}"
        exit 1
    fi
}

# Main installation
main() {
    clear

    echo -e "${CYAN}"
    echo "  ⌨️  Hyprland Keyboard Hotswap"
    echo -e "${DIM}     One-line installer${NC}\n"

    # Check dependencies
    check_deps

    # Ensure external keyboard is connected
    echo -e "${YELLOW}⚠${NC}  Please ensure your external keyboard is connected\n"
    echo -e "${DIM}Press Enter to continue...${NC}"
    read -s < /dev/tty
    echo

    # Create temp directory
    echo -e "${DIM}Creating temporary directory...${NC}"
    mkdir -p "$TEMP_DIR" || {
        echo -e "${RED}Failed to create temp directory${NC}"
        exit 1
    }
    cd "$TEMP_DIR"

    # Download required files
    echo -e "${DIM}Downloading setup files...${NC}"
    mkdir -p scripts

    echo -e "${DIM}  • Downloading arrow-menu.sh...${NC}"
    download "scripts/arrow-menu.sh" "scripts/arrow-menu.sh"

    echo -e "${DIM}  • Downloading simple-setup-arrow.sh...${NC}"
    download "scripts/simple-setup-arrow.sh" "scripts/simple-setup-arrow.sh"

    echo -e "${DIM}  • Downloading keyboard-switch-generic.sh...${NC}"
    download "scripts/keyboard-switch-generic.sh" "scripts/keyboard-switch-generic.sh"

    chmod +x scripts/*.sh

    # Run the simple setup with arrow navigation
    echo -e "${DIM}Starting setup wizard...${NC}"
    sleep 1
    if ! ./scripts/simple-setup-arrow.sh; then
        echo -e "${RED}Setup cancelled${NC}"
        exit 1
    fi

    # Check if config was created
    if [ ! -f "$HYPR_CONFIG_DIR/keyboard-hotswap.conf" ]; then
        echo -e "${RED}Configuration was not created${NC}"
        exit 1
    fi

    # Load the configuration
    source "$HYPR_CONFIG_DIR/keyboard-hotswap.conf"

    # Install the switch script
    echo -e "${DIM}Installing scripts...${NC}"
    cp scripts/keyboard-switch-generic.sh "$HYPR_CONFIG_DIR/keyboard-switch.sh"
    chmod +x "$HYPR_CONFIG_DIR/keyboard-switch.sh"

    # Create init script
    cat > "$HYPR_CONFIG_DIR/keyboard-init.sh" <<'EOF'
#!/bin/bash
# Initialize keyboard configuration on startup
sleep 2
$HOME/.config/hypr/keyboard-switch.sh check
EOF
    chmod +x "$HYPR_CONFIG_DIR/keyboard-init.sh"

    # Add to autostart if not already present
    if [ ! -f "$HYPR_CONFIG_DIR/autostart.conf" ]; then
        echo "# Extra autostart processes" > "$HYPR_CONFIG_DIR/autostart.conf"
    fi

    if ! grep -q "keyboard-init.sh" "$HYPR_CONFIG_DIR/autostart.conf"; then
        echo "exec-once = $HYPR_CONFIG_DIR/keyboard-init.sh" >> "$HYPR_CONFIG_DIR/autostart.conf"
    fi

    # Generate and install udev rule
    VENDOR_ID="${EXTERNAL_KEYBOARD_ID%:*}"
    PRODUCT_ID="${EXTERNAL_KEYBOARD_ID#*:}"

    cat > /tmp/99-hypr-keyboard.rules <<EOF
# Hyprland keyboard auto-switching
# Generated for: $EXTERNAL_KEYBOARD_DESC

ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="$VENDOR_ID", ATTR{idProduct}=="$PRODUCT_ID", RUN+="$HYPR_CONFIG_DIR/keyboard-switch.sh add"
ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="$VENDOR_ID", ENV{ID_MODEL_ID}=="$PRODUCT_ID", RUN+="$HYPR_CONFIG_DIR/keyboard-switch.sh remove"
EOF

    echo -e "\n${YELLOW}Installing system rules (requires sudo)...${NC}"
    sudo cp /tmp/99-hypr-keyboard.rules /etc/udev/rules.d/99-hypr-keyboard.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger

    # Apply configuration now
    "$HYPR_CONFIG_DIR/keyboard-switch.sh" check

    # Reload Hyprland if running
    if pgrep -x "Hyprland" > /dev/null; then
        hyprctl reload 2>/dev/null || true
    fi

    # Success!
    echo -e "\n${GREEN}${BOLD}✨ All done!${NC}\n"
    echo -e "Your keyboard settings will now switch automatically.\n"
    echo -e "${DIM}To reconfigure: Run this installer again"
    echo -e "To uninstall: Visit ${REPO}${NC}\n"
}

# Run installation
main "$@"
#!/bin/bash

# Hyprland Keyboard Hotswap - Simple Local Installer
# For users who clone the repository

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_CONFIG_DIR="$HOME/.config/hypr"

# Check if running with sudo
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Do not run with sudo. It will ask when needed.${NC}"
    exit 1
fi

# Backup existing config if present
if [[ -f "$HYPR_CONFIG_DIR/input.conf" ]]; then
    BACKUP_FILE="$HYPR_CONFIG_DIR/input.conf.bak.$(date +%s)"
    echo -e "${DIM}Backing up existing config to $BACKUP_FILE${NC}"
    cp "$HYPR_CONFIG_DIR/input.conf" "$BACKUP_FILE"
fi

# Run the simple setup
chmod +x "$SCRIPT_DIR/scripts/simple-setup.sh"
if ! "$SCRIPT_DIR/scripts/simple-setup.sh"; then
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
cp "$SCRIPT_DIR/scripts/keyboard-switch-generic.sh" "$HYPR_CONFIG_DIR/keyboard-switch.sh"
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
    echo "" >> "$HYPR_CONFIG_DIR/autostart.conf"
    echo "# Initialize keyboard configuration" >> "$HYPR_CONFIG_DIR/autostart.conf"
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
rm /tmp/99-hypr-keyboard.rules

# Apply configuration now
"$HYPR_CONFIG_DIR/keyboard-switch.sh" check

# Reload Hyprland if running
if pgrep -x "Hyprland" > /dev/null; then
    echo -e "${DIM}Reloading Hyprland...${NC}"
    hyprctl reload 2>/dev/null || true
fi

# Success!
echo -e "\n${GREEN}${BOLD}✨ All done!${NC}\n"
echo -e "Your keyboard settings will now switch automatically.\n"
echo -e "${DIM}To reconfigure: Run ./install-simple.sh again"
echo -e "To uninstall: Run ./uninstall.sh${NC}\n"
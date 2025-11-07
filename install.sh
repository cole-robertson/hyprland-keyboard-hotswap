#!/bin/bash

# Hyprland Keyboard Hotswap Installer
# Automatically switches keyboard configuration when external keyboard is connected/disconnected

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HYPR_CONFIG_DIR="$HOME/.config/hypr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Function to check if running with sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_msg "Error: Do not run this script with sudo. It will ask for sudo when needed." "$RED"
        exit 1
    fi
}

# Function to backup existing configuration
backup_config() {
    if [[ -f "$HYPR_CONFIG_DIR/input.conf" ]]; then
        BACKUP_FILE="$HYPR_CONFIG_DIR/input.conf.bak.$(date +%s)"
        print_msg "Backing up existing input.conf to $BACKUP_FILE" "$YELLOW"
        cp "$HYPR_CONFIG_DIR/input.conf" "$BACKUP_FILE"
    fi
}

# Function to install configuration files
install_configs() {
    print_msg "Installing configuration files..." "$GREEN"

    # Copy laptop and external configs
    cp "$SCRIPT_DIR/configs/input-laptop.conf" "$HYPR_CONFIG_DIR/input-laptop.conf"
    cp "$SCRIPT_DIR/configs/input-external.conf" "$HYPR_CONFIG_DIR/input-external.conf"

    # Copy scripts
    cp "$SCRIPT_DIR/scripts/keyboard-switch.sh" "$HYPR_CONFIG_DIR/keyboard-switch.sh"
    cp "$SCRIPT_DIR/scripts/keyboard-init.sh" "$HYPR_CONFIG_DIR/keyboard-init.sh"

    # Make scripts executable
    chmod +x "$HYPR_CONFIG_DIR/keyboard-switch.sh"
    chmod +x "$HYPR_CONFIG_DIR/keyboard-init.sh"

    print_msg "Configuration files installed successfully" "$GREEN"
}

# Function to detect keyboard and set initial config
setup_initial_config() {
    print_msg "Detecting keyboard and setting initial configuration..." "$YELLOW"

    if lsusb | grep -q "05ac:024f"; then
        print_msg "Flow84@Lofree keyboard detected - using external configuration" "$GREEN"
        cp "$HYPR_CONFIG_DIR/input-external.conf" "$HYPR_CONFIG_DIR/input.conf"
    else
        print_msg "No external keyboard detected - using laptop configuration" "$GREEN"
        cp "$HYPR_CONFIG_DIR/input-laptop.conf" "$HYPR_CONFIG_DIR/input.conf"
    fi
}

# Function to add autostart entry
setup_autostart() {
    print_msg "Setting up autostart..." "$YELLOW"

    # Check if autostart.conf exists
    if [[ ! -f "$HYPR_CONFIG_DIR/autostart.conf" ]]; then
        print_msg "Creating autostart.conf..." "$YELLOW"
        echo "# Extra autostart processes" > "$HYPR_CONFIG_DIR/autostart.conf"
    fi

    # Check if the init script is already in autostart
    if grep -q "keyboard-init.sh" "$HYPR_CONFIG_DIR/autostart.conf"; then
        print_msg "Autostart entry already exists" "$YELLOW"
    else
        echo "" >> "$HYPR_CONFIG_DIR/autostart.conf"
        echo "# Initialize keyboard configuration based on connected devices" >> "$HYPR_CONFIG_DIR/autostart.conf"
        echo "exec-once = $HYPR_CONFIG_DIR/keyboard-init.sh" >> "$HYPR_CONFIG_DIR/autostart.conf"
        print_msg "Added autostart entry" "$GREEN"
    fi
}

# Function to install udev rule
install_udev_rule() {
    print_msg "Installing udev rule..." "$YELLOW"

    # Update the udev rule to use the correct path
    sed "s|/home/cole|$HOME|g" "$SCRIPT_DIR/udev/99-hypr-keyboard.rules" > /tmp/99-hypr-keyboard.rules

    print_msg "Installing udev rule (requires sudo)..." "$YELLOW"
    sudo cp /tmp/99-hypr-keyboard.rules /etc/udev/rules.d/99-hypr-keyboard.rules

    print_msg "Reloading udev rules..." "$YELLOW"
    sudo udevadm control --reload-rules
    sudo udevadm trigger

    rm /tmp/99-hypr-keyboard.rules
    print_msg "Udev rule installed successfully" "$GREEN"
}

# Function to test the installation
test_installation() {
    print_msg "\nTesting installation..." "$YELLOW"

    # Check if keyboard is connected
    if lsusb | grep -q "05ac:024f"; then
        print_msg "✓ Flow84@Lofree keyboard detected" "$GREEN"
    else
        print_msg "✗ Flow84@Lofree keyboard not detected" "$YELLOW"
    fi

    # Check configuration files
    [[ -f "$HYPR_CONFIG_DIR/input-laptop.conf" ]] && print_msg "✓ Laptop config installed" "$GREEN" || print_msg "✗ Laptop config missing" "$RED"
    [[ -f "$HYPR_CONFIG_DIR/input-external.conf" ]] && print_msg "✓ External config installed" "$GREEN" || print_msg "✗ External config missing" "$RED"
    [[ -f "$HYPR_CONFIG_DIR/keyboard-switch.sh" ]] && print_msg "✓ Switch script installed" "$GREEN" || print_msg "✗ Switch script missing" "$RED"
    [[ -f "$HYPR_CONFIG_DIR/keyboard-init.sh" ]] && print_msg "✓ Init script installed" "$GREEN" || print_msg "✗ Init script missing" "$RED"
    [[ -f "/etc/udev/rules.d/99-hypr-keyboard.rules" ]] && print_msg "✓ Udev rule installed" "$GREEN" || print_msg "✗ Udev rule missing" "$RED"

    # Check current configuration
    if grep -q "altwin:swap_lalt_lwin" "$HYPR_CONFIG_DIR/input.conf"; then
        print_msg "Current config: Laptop mode (keys swapped)" "$YELLOW"
    else
        print_msg "Current config: External mode (keys normal)" "$YELLOW"
    fi
}

# Main installation flow
main() {
    print_msg "\n╔════════════════════════════════════════╗" "$GREEN"
    print_msg "║  Hyprland Keyboard Hotswap Installer  ║" "$GREEN"
    print_msg "╚════════════════════════════════════════╝\n" "$GREEN"

    check_sudo

    print_msg "This will install keyboard hotswap configuration for Hyprland." "$YELLOW"
    print_msg "It will detect your Flow84@Lofree keyboard and automatically" "$YELLOW"
    print_msg "switch between laptop and external keyboard configurations.\n" "$YELLOW"

    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Installation cancelled" "$RED"
        exit 1
    fi

    backup_config
    install_configs
    setup_initial_config
    setup_autostart
    install_udev_rule
    test_installation

    print_msg "\n✓ Installation complete!" "$GREEN"
    print_msg "\nThe keyboard configuration will now automatically switch when you:" "$YELLOW"
    print_msg "  • Connect your Flow84@Lofree keyboard (uses normal keys)" "$YELLOW"
    print_msg "  • Disconnect your keyboard (swaps Alt/Super keys)" "$YELLOW"
    print_msg "\nManual commands available:" "$YELLOW"
    print_msg "  • Test: $HYPR_CONFIG_DIR/keyboard-switch.sh check" "$YELLOW"
    print_msg "  • Force laptop mode: $HYPR_CONFIG_DIR/keyboard-switch.sh remove" "$YELLOW"
    print_msg "  • Force external mode: $HYPR_CONFIG_DIR/keyboard-switch.sh add" "$YELLOW"

    # Ask if user wants to reload Hyprland
    if pgrep -x "Hyprland" > /dev/null; then
        print_msg "\nHyprland is running. Would you like to reload the configuration now?" "$YELLOW"
        read -p "(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            hyprctl reload
            print_msg "Hyprland configuration reloaded" "$GREEN"
        fi
    fi
}

# Run main function
main "$@"
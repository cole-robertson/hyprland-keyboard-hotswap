#!/bin/bash

# Hyprland Keyboard Hotswap Uninstaller

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HYPR_CONFIG_DIR="$HOME/.config/hypr"

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Main uninstall function
uninstall() {
    print_msg "\n╔══════════════════════════════════════════╗" "$RED"
    print_msg "║  Hyprland Keyboard Hotswap Uninstaller  ║" "$RED"
    print_msg "╚══════════════════════════════════════════╝\n" "$RED"

    print_msg "This will remove the keyboard hotswap configuration." "$YELLOW"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Uninstall cancelled" "$GREEN"
        exit 0
    fi

    # Remove installed files
    print_msg "\nRemoving configuration files..." "$YELLOW"

    [[ -f "$HYPR_CONFIG_DIR/input-laptop.conf" ]] && rm "$HYPR_CONFIG_DIR/input-laptop.conf" && print_msg "Removed input-laptop.conf" "$GREEN"
    [[ -f "$HYPR_CONFIG_DIR/input-external.conf" ]] && rm "$HYPR_CONFIG_DIR/input-external.conf" && print_msg "Removed input-external.conf" "$GREEN"
    [[ -f "$HYPR_CONFIG_DIR/keyboard-switch.sh" ]] && rm "$HYPR_CONFIG_DIR/keyboard-switch.sh" && print_msg "Removed keyboard-switch.sh" "$GREEN"
    [[ -f "$HYPR_CONFIG_DIR/keyboard-init.sh" ]] && rm "$HYPR_CONFIG_DIR/keyboard-init.sh" && print_msg "Removed keyboard-init.sh" "$GREEN"

    # Remove udev rule
    if [[ -f "/etc/udev/rules.d/99-hypr-keyboard.rules" ]]; then
        print_msg "Removing udev rule (requires sudo)..." "$YELLOW"
        sudo rm "/etc/udev/rules.d/99-hypr-keyboard.rules"
        sudo udevadm control --reload-rules
        print_msg "Udev rule removed" "$GREEN"
    fi

    # Remove autostart entry
    if [[ -f "$HYPR_CONFIG_DIR/autostart.conf" ]]; then
        if grep -q "keyboard-init.sh" "$HYPR_CONFIG_DIR/autostart.conf"; then
            print_msg "Removing autostart entry..." "$YELLOW"
            sed -i '/keyboard-init.sh/d' "$HYPR_CONFIG_DIR/autostart.conf"
            sed -i '/Initialize keyboard configuration/d' "$HYPR_CONFIG_DIR/autostart.conf"
            print_msg "Autostart entry removed" "$GREEN"
        fi
    fi

    # Restore backup if available
    LATEST_BACKUP=$(ls -t "$HYPR_CONFIG_DIR"/input.conf.bak.* 2>/dev/null | head -n1)
    if [[ -n "$LATEST_BACKUP" ]]; then
        print_msg "\nFound backup: $LATEST_BACKUP" "$YELLOW"
        read -p "Do you want to restore it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$LATEST_BACKUP" "$HYPR_CONFIG_DIR/input.conf"
            print_msg "Backup restored" "$GREEN"
        fi
    fi

    print_msg "\n✓ Uninstall complete!" "$GREEN"
}

# Run uninstall
uninstall
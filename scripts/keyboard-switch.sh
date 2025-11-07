#!/bin/bash

# Script to switch Hyprland input configuration based on keyboard connection
# This script is triggered by udev rules

ACTION=$1
CONFIG_DIR="$HOME/.config/hypr"
LAPTOP_CONFIG="$CONFIG_DIR/input-laptop.conf"
EXTERNAL_CONFIG="$CONFIG_DIR/input-external.conf"
ACTIVE_CONFIG="$CONFIG_DIR/input.conf"
LOG_FILE="/tmp/keyboard-switch.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to reload Hyprland configuration
reload_hyprland() {
    # Check if Hyprland is running
    if pgrep -x "Hyprland" > /dev/null; then
        # Get the Hyprland instance signature
        export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /tmp/hypr 2>/dev/null | head -n 1 | grep -v lock)

        # Send reload signal to Hyprland
        hyprctl reload
        log_message "Hyprland configuration reloaded"
    else
        log_message "Hyprland is not running, skipping reload"
    fi
}

# Main logic
case "$ACTION" in
    "connected"|"add")
        log_message "External keyboard connected, switching to external configuration"
        cp "$EXTERNAL_CONFIG" "$ACTIVE_CONFIG"
        reload_hyprland
        ;;
    "disconnected"|"remove")
        log_message "External keyboard disconnected, switching to laptop configuration"
        cp "$LAPTOP_CONFIG" "$ACTIVE_CONFIG"
        reload_hyprland
        ;;
    "check")
        # Check if keyboard is connected
        if lsusb | grep -q "05ac:024f"; then
            log_message "External keyboard detected during check, using external configuration"
            cp "$EXTERNAL_CONFIG" "$ACTIVE_CONFIG"
        else
            log_message "No external keyboard detected during check, using laptop configuration"
            cp "$LAPTOP_CONFIG" "$ACTIVE_CONFIG"
        fi
        reload_hyprland
        ;;
    *)
        log_message "Unknown action: $ACTION"
        exit 1
        ;;
esac

exit 0
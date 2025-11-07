#!/bin/bash

# Initialize keyboard configuration on Hyprland startup
# Add this to your autostart.conf or hyprland.conf

# Wait a moment for USB devices to be fully initialized
sleep 2

# Check and set the appropriate keyboard configuration
$HOME/.config/hypr/keyboard-switch.sh check
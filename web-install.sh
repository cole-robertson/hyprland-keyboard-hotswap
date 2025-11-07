#!/bin/bash

# Hyprland Keyboard Hotswap - Web Installer
# One-liner installation script that downloads and sets up everything

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# GitHub repository
REPO_OWNER="cole-robertson"
REPO_NAME="hyprland-keyboard-hotswap"
BRANCH="master"
GITHUB_RAW="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# Temporary directory for installation
TEMP_DIR="/tmp/hyprland-keyboard-hotswap-$$"

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    # Check for required commands
    for cmd in curl git hyprctl; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_msg "Missing required dependencies: ${missing_deps[*]}" "$RED"
        print_msg "Please install them first and try again." "$YELLOW"
        exit 1
    fi
}

# Function to download file from GitHub
download_file() {
    local file_path="$1"
    local dest="$2"
    local url="${GITHUB_RAW}/${file_path}"

    if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
        return 0
    else
        print_msg "Failed to download: $file_path" "$RED"
        return 1
    fi
}

# Function to cleanup on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Main installation
main() {
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║     HYPRLAND KEYBOARD HOTSWAP INSTALLER       ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    print_msg "\nChecking dependencies..." "$YELLOW"
    check_dependencies
    print_msg "✓ All dependencies found" "$GREEN"

    print_msg "\nThis installer will:" "$YELLOW"
    print_msg "  • Download the keyboard hotswap tool" "$NC"
    print_msg "  • Detect your external keyboard" "$NC"
    print_msg "  • Let you configure key mappings" "$NC"
    print_msg "  • Set up automatic switching" "$NC"

    print_msg "\n⚠️  Please ensure your external keyboard is connected!" "$YELLOW"

    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Installation cancelled" "$RED"
        exit 0
    fi

    # Create temporary directory
    print_msg "\nPreparing installation..." "$YELLOW"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    # Download installation files
    print_msg "Downloading files from GitHub..." "$YELLOW"

    # Create directory structure
    mkdir -p scripts

    # Download scripts
    files_to_download=(
        "scripts/detect-keyboard.sh"
        "scripts/keyboard-switch-generic.sh"
        "install-interactive.sh"
    )

    for file in "${files_to_download[@]}"; do
        print_msg "  • Downloading $file..." "$NC"
        if ! download_file "$file" "$file"; then
            print_msg "Download failed. Please check your internet connection." "$RED"
            exit 1
        fi
        chmod +x "$file"
    done

    print_msg "✓ Files downloaded successfully" "$GREEN"

    # Run the interactive installer
    print_msg "\nStarting interactive setup..." "$BLUE"

    if [ -f "./install-interactive.sh" ]; then
        # The installer expects to be run from the repo directory
        # We need to modify it slightly for web installation

        # Create a modified version that works with our temp directory
        cat > "./install-web.sh" << 'INSTALLER'
#!/bin/bash

# Web-modified version of install-interactive.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
HYPR_CONFIG_DIR="$HOME/.config/hypr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HYPR_CONFIG_DIR/keyboard-hotswap.conf"

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

# Function to run interactive configuration
configure_keyboard() {
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║       KEYBOARD CONFIGURATION SETUP            ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    print_msg "\nStarting interactive keyboard configuration..." "$YELLOW"

    # Make detect script executable
    chmod +x "$SCRIPT_DIR/scripts/detect-keyboard.sh"

    # Run the interactive configuration
    if ! "$SCRIPT_DIR/scripts/detect-keyboard.sh"; then
        print_msg "\nConfiguration failed. Please ensure your external keyboard is connected." "$RED"
        exit 1
    fi

    # Check if configuration was created
    if [ ! -f "$CONFIG_FILE" ]; then
        print_msg "\nConfiguration file was not created. Setup failed." "$RED"
        exit 1
    fi

    print_msg "\nConfiguration saved successfully!" "$GREEN"
}

# Function to install configuration files
install_configs() {
    print_msg "\nInstalling configuration files..." "$GREEN"

    # Load the configuration
    source "$CONFIG_FILE"

    # Copy the generic switch script
    cp "$SCRIPT_DIR/scripts/keyboard-switch-generic.sh" "$HYPR_CONFIG_DIR/keyboard-switch.sh"
    chmod +x "$HYPR_CONFIG_DIR/keyboard-switch.sh"

    # Create initialization script
    cat > "$HYPR_CONFIG_DIR/keyboard-init.sh" <<'EOF'
#!/bin/bash
# Initialize keyboard configuration on Hyprland startup
# Wait a moment for USB devices to be fully initialized
sleep 2
# Check and set the appropriate keyboard configuration
$HOME/.config/hypr/keyboard-switch.sh check
EOF
    chmod +x "$HYPR_CONFIG_DIR/keyboard-init.sh"

    print_msg "Scripts installed successfully" "$GREEN"
}

# Function to generate and apply initial config
setup_initial_config() {
    print_msg "\nApplying initial configuration..." "$YELLOW"

    # Run the check to set up initial config
    "$HYPR_CONFIG_DIR/keyboard-switch.sh" check

    if [ $? -eq 0 ]; then
        print_msg "Initial configuration applied" "$GREEN"
    else
        print_msg "Warning: Could not apply initial configuration" "$YELLOW"
    fi
}

# Function to add autostart entry
setup_autostart() {
    print_msg "\nSetting up autostart..." "$YELLOW"

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

# Function to generate and install udev rule
install_udev_rule() {
    print_msg "\nGenerating udev rule..." "$YELLOW"

    # Load configuration to get USB ID
    source "$CONFIG_FILE"

    # Extract vendor and product IDs
    VENDOR_ID="${EXTERNAL_KEYBOARD_ID%:*}"
    PRODUCT_ID="${EXTERNAL_KEYBOARD_ID#*:}"

    # Generate udev rule
    cat > /tmp/99-hypr-keyboard.rules <<EOF
# Udev rule for Hyprland keyboard configuration switching
# Generated for: $EXTERNAL_KEYBOARD_DESC

# When the external keyboard is connected
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="$VENDOR_ID", ATTR{idProduct}=="$PRODUCT_ID", RUN+="$HYPR_CONFIG_DIR/keyboard-switch.sh add"

# When the external keyboard is disconnected
ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="$VENDOR_ID", ENV{ID_MODEL_ID}=="$PRODUCT_ID", RUN+="$HYPR_CONFIG_DIR/keyboard-switch.sh remove"
EOF

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
    print_msg "\n╔════════════════════════════════════════════════╗" "$MAGENTA"
    print_msg "║           INSTALLATION TEST                   ║" "$MAGENTA"
    print_msg "╚════════════════════════════════════════════════╝" "$MAGENTA"

    # Load configuration
    source "$CONFIG_FILE"

    # Check if keyboard is connected
    if lsusb | grep -q "$EXTERNAL_KEYBOARD_ID"; then
        print_msg "✓ External keyboard detected: ${EXTERNAL_KEYBOARD_DESC%%ID*}" "$GREEN"
    else
        print_msg "✗ External keyboard not currently connected" "$YELLOW"
    fi

    # Check configuration files
    [[ -f "$CONFIG_FILE" ]] && print_msg "✓ Configuration file exists" "$GREEN" || print_msg "✗ Configuration missing" "$RED"
    [[ -f "$HYPR_CONFIG_DIR/keyboard-switch.sh" ]] && print_msg "✓ Switch script installed" "$GREEN" || print_msg "✗ Switch script missing" "$RED"
    [[ -f "$HYPR_CONFIG_DIR/keyboard-init.sh" ]] && print_msg "✓ Init script installed" "$GREEN" || print_msg "✗ Init script missing" "$RED"
    [[ -f "/etc/udev/rules.d/99-hypr-keyboard.rules" ]] && print_msg "✓ Udev rule installed" "$GREEN" || print_msg "✗ Udev rule missing" "$RED"

    # Show current mappings
    print_msg "\nCurrent configuration:" "$YELLOW"
    print_msg "  External keyboard: ${EXTERNAL_KB_OPTIONS:-No remapping}" "$NC"
    print_msg "  Laptop keyboard: ${LAPTOP_KB_OPTIONS:-No remapping}" "$NC"
}

# Main installation flow
main() {
    check_sudo

    # Run configuration first
    configure_keyboard

    # Now install everything
    backup_config
    install_configs
    setup_initial_config
    setup_autostart
    install_udev_rule
    test_installation

    print_msg "\n╔════════════════════════════════════════════════╗" "$GREEN"
    print_msg "║         ✓ INSTALLATION COMPLETE!               ║" "$GREEN"
    print_msg "╚════════════════════════════════════════════════╝" "$GREEN"

    print_msg "\nYour keyboard will now automatically switch configurations when:" "$YELLOW"
    print_msg "  • You connect your external keyboard" "$NC"
    print_msg "  • You disconnect your external keyboard" "$NC"
    print_msg "  • Your system starts up" "$NC"

    print_msg "\nUseful commands:" "$BLUE"
    print_msg "  • Test current setup: $HYPR_CONFIG_DIR/keyboard-switch.sh check" "$NC"
    print_msg "  • View configuration: cat $CONFIG_FILE" "$NC"
    print_msg "  • Check logs: tail /tmp/keyboard-switch.log" "$NC"

    # Ask if user wants to reload Hyprland
    if pgrep -x "Hyprland" > /dev/null; then
        print_msg "\nWould you like to reload Hyprland now to apply changes?" "$YELLOW"
        read -p "(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            hyprctl reload
            print_msg "✓ Hyprland configuration reloaded" "$GREEN"
        fi
    fi

    print_msg "\nTo reconfigure later, visit:" "$BLUE"
    print_msg "  https://github.com/${REPO_OWNER}/${REPO_NAME}" "$NC"
}

# Run main function
main "$@"
INSTALLER

        chmod +x "./install-web.sh"
        ./install-web.sh
    else
        print_msg "Installation script not found!" "$RED"
        exit 1
    fi

    print_msg "\n✓ Installation complete!" "$GREEN"
    print_msg "\nFor more information, visit:" "$BLUE"
    print_msg "  https://github.com/${REPO_OWNER}/${REPO_NAME}" "$NC"
}

# Run main installation
main "$@"
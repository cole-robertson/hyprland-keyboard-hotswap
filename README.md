# Hyprland Keyboard Hotswap

Automatically switch Hyprland keyboard configuration when external keyboards are connected or disconnected. Perfect for laptop users who switch between built-in and external keyboards with different key layouts.

## Features

- **Automatic Detection**: Detects when your external keyboard is connected/disconnected
- **Instant Switching**: Configuration changes apply immediately without restart
- **Persistent Settings**: Correct configuration loads on system startup
- **Easy Installation**: One-command setup with automatic backup

## Use Case

This tool was created for laptop users who:
- Use `altwin:swap_lalt_lwin` to swap Alt/Super keys on their laptop keyboard
- Want normal key behavior when using an external keyboard
- Need automatic switching without manual configuration changes

## Quick Start

```bash
# Clone and install
git clone https://github.com/cole-robertson/hyprland-keyboard-hotswap.git
cd hyprland-keyboard-hotswap
chmod +x install.sh
./install.sh
```

## What Gets Installed

- **Configuration Files**: Two Hyprland input configs (laptop/external)
- **Switch Scripts**: Automatic detection and switching logic
- **Udev Rule**: Triggers on USB keyboard connect/disconnect events
- **Autostart Entry**: Ensures correct config on system startup

## File Locations

After installation, files are placed in:
```
~/.config/hypr/
├── input.conf                 # Active configuration (auto-managed)
├── input-laptop.conf         # Laptop keyboard config (keys swapped)
├── input-external.conf       # External keyboard config (keys normal)
├── keyboard-switch.sh        # Main switching script
└── keyboard-init.sh          # Startup initialization script

/etc/udev/rules.d/
└── 99-hypr-keyboard.rules   # USB detection rule
```

## Manual Commands

Test or force specific configurations:

```bash
# Check current status and auto-detect
~/.config/hypr/keyboard-switch.sh check

# Force laptop mode (keys swapped)
~/.config/hypr/keyboard-switch.sh remove

# Force external mode (keys normal)
~/.config/hypr/keyboard-switch.sh add
```

## Customization

### Different Keyboard

Edit the udev rule to match your keyboard's vendor and product ID:

1. Find your keyboard's ID:
   ```bash
   lsusb
   # Look for your keyboard, note the ID (e.g., 05ac:024f)
   ```

2. Update `/etc/udev/rules.d/99-hypr-keyboard.rules`:
   ```bash
   # Replace 05ac and 024f with your keyboard's vendor and product ID
   ATTR{idVendor}=="YOUR_VENDOR", ATTR{idProduct}=="YOUR_PRODUCT"
   ```

3. Reload udev:
   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

### Different Key Mappings

Edit the configuration files in `~/.config/hypr/`:
- `input-laptop.conf`: Configuration for laptop keyboard
- `input-external.conf`: Configuration for external keyboard

Common `kb_options`:
- `altwin:swap_lalt_lwin` - Swap left Alt and Super
- `caps:swapescape` - Swap Caps Lock and Escape
- `compose:ralt` - Right Alt as compose key

## Troubleshooting

### Configuration Not Switching

1. Check if udev rule is installed:
   ```bash
   ls /etc/udev/rules.d/99-hypr-keyboard.rules
   ```

2. Check logs:
   ```bash
   tail -f /tmp/keyboard-switch.log
   ```

3. Test manual switching:
   ```bash
   ~/.config/hypr/keyboard-switch.sh check
   ```

### Keyboard Not Detected

1. Verify USB connection:
   ```bash
   lsusb | grep -i keyboard
   ```

2. Check device permissions:
   ```bash
   ls -la /dev/input/by-id/
   ```

## Uninstall

Remove all components:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will:
- Remove all installed configuration files
- Remove the udev rule
- Remove autostart entries
- Optionally restore your backup

## Requirements

- Hyprland window manager
- systemd/udev (standard on most Linux distributions)
- USB keyboard with unique vendor/product ID

## License

MIT License - Feel free to modify and distribute as needed.

## Author

Created by Cole Robertson for personal use with Flow84@Lofree keyboard.
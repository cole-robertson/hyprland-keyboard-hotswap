# Hyprland Keyboard Hotswap

Automatically switch Hyprland keyboard configuration when external keyboards are connected or disconnected. Perfect for laptop users who switch between built-in and external keyboards with different key layouts.

## Features

- **Interactive Setup**: Automatically detects YOUR keyboard and lets you choose key mappings
- **Universal Support**: Works with ANY USB keyboard - not limited to specific models
- **Custom Key Mapping**: Choose which physical key acts as Super, Alt, or Ctrl
- **Automatic Detection**: Switches configuration when you plug/unplug
- **Instant Switching**: Changes apply immediately without restart
- **Persistent Settings**: Correct configuration loads on system startup
- **Easy Installation**: Interactive setup guides you through the process

## Use Case

This tool is perfect for:
- Laptop users switching between built-in and external keyboards
- Mac users who want Cmd key to work as Super on Linux
- Anyone who wants different key mappings for different keyboards
- Users with multiple keyboards who want consistent behavior

## Quick Start - Interactive Setup (NEW!)

The new interactive installer will:
1. Detect your external keyboard automatically
2. Let you test and choose your preferred key mappings
3. Configure different behaviors for laptop vs external keyboard
4. Set up automatic switching

```bash
# Clone and install interactively
git clone https://github.com/cole-robertson/hyprland-keyboard-hotswap.git
cd hyprland-keyboard-hotswap
chmod +x install-interactive.sh
./install-interactive.sh
```

### During Setup, You Can Choose:

**For your external keyboard:**
- Keep default (no changes)
- Swap Alt ↔ Super (left side only)
- Swap Alt ↔ Super (both sides)
- Mac-style: Cmd acts as Super, Option as Alt
- Custom mapping (advanced)

**For your laptop keyboard:**
- Swap Alt ↔ Super (Mac-like experience)
- Keep default (no changes)
- Same as external keyboard

## Original Setup (Specific Keyboard)

If you prefer the original non-interactive setup:

```bash
# Use original installer
chmod +x install.sh
./install.sh
```

## What Gets Installed

- **Configuration Files**: Your custom keyboard settings and Hyprland configs
- **Switch Scripts**: Automatic detection and switching logic
- **Udev Rule**: Triggers on USB keyboard connect/disconnect events
- **Autostart Entry**: Ensures correct config on system startup

## File Locations

After installation, files are placed in:
```
~/.config/hypr/
├── input.conf                 # Active configuration (auto-managed)
├── keyboard-hotswap.conf     # Your keyboard settings and mappings
├── keyboard-switch.sh        # Main switching script
└── keyboard-init.sh          # Startup initialization script

/etc/udev/rules.d/
└── 99-hypr-keyboard.rules   # USB detection rule (generated for your keyboard)
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

### Reconfigure Your Keyboard

To change your keyboard or key mappings, simply run the interactive installer again:

```bash
./install-interactive.sh
```

It will:
- Detect your current keyboard
- Let you choose new mappings
- Update all configurations automatically

### Manual Configuration

If you want to manually edit your settings:

1. Edit your saved configuration:
   ```bash
   nano ~/.config/hypr/keyboard-hotswap.conf
   ```

2. Modify the key mappings:
   ```bash
   # Example mappings you can use:
   LAPTOP_KB_OPTIONS="altwin:swap_lalt_lwin"     # Swap left Alt ↔ Super
   EXTERNAL_KB_OPTIONS="altwin:swap_alt_win"      # Swap all Alt ↔ Super
   ```

3. Apply changes:
   ```bash
   ~/.config/hypr/keyboard-switch.sh check
   ```

### Different Key Mappings

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

Created by Cole Robertson - initially for Flow84@Lofree keyboard, now supports any USB keyboard with interactive configuration.
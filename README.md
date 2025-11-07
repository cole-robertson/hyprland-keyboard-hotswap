# Hyprland Keyboard Hotswap

Automatically switch Hyprland keyboard configuration when external keyboards are connected or disconnected. Perfect for laptop users who switch between built-in and external keyboards with different key layouts.

## 🚀 One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/cole-robertson/hyprland-keyboard-hotswap/master/web-install-simple.sh | bash
```

**That's it!** In 30 seconds you'll have:
- ✅ Your external keyboard detected
- ✅ **REAL key detection** - press actual keys!
- ✅ Automatic switching enabled

How it works:
1. **Press and hold** the key you want as Super
2. **We detect it** with a countdown timer
3. **Confirm which key** you pressed
4. **Done!** - Actual key detection!

**Note:** Connect your external keyboard before running!

## Features

- **30-Second Setup**: Beautiful, minimal CLI wizard
- **Universal Support**: Works with ANY USB keyboard
- **Smart Defaults**: Sensible presets for common layouts
- **Automatic Switching**: Detects when you plug/unplug
- **Zero Config**: Works immediately after setup
- **Persistent**: Correct layout on every boot

## What It Looks Like

```
╔══════════════════════════════════════════════════════╗
║                                                      ║
║        ⌨️  REAL KEY DETECTION SETUP                  ║
║                                                      ║
║    Actually press the keys you want to use!         ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

Let's test your external keyboard!

┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬──────┐
│Esc│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ - │ = │ Bksp │
├───┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬────┤
│ Tab │ Q │ W │ E │ R │ T │ Y │ U │ I │ O │ P │ [ │ ] │ \  │
├─────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴────┤
│ Caps │ A │ S │ D │ F │ G │ H │ J │ K │ L │ ; │ ' │ Enter │
├──────┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴─┬─┴───────┤
│ Shift  │ Z │ X │ C │ V │ B │ N │ M │ , │ . │ / │  Shift  │
├────┬───┴┬──┴─┬─┴───┴───┴───┴───┴───┴──┬┴───┼───┴┬────┬───┤
│Ctrl│Alt │Cmd │         Space          │Cmd │Alt │Menu│Ctl│
└────┴────┴────┴────────────────────────┴────┴────┴────┴───┘

NOW: Press and HOLD the key you want as SUPER...
(The key for Super+Q, Super+Enter, etc)

Listening for keypress...
Press the key NOW...
Waiting... 3 2 1

✓ Key detected!

Which key did you actually press?
1) Left Alt (beside spacebar)
2) Left Cmd/Super/Win (between Ctrl and Alt)
3) Right Alt
4) I want to choose from a menu instead
```

**REAL key detection** - Actually press the key you want!

## Use Case

This tool is perfect for:
- Laptop users switching between built-in and external keyboards
- Mac users who want Cmd key to work as Super on Linux
- Anyone who wants different key mappings for different keyboards
- Users with multiple keyboards who want consistent behavior

## Installation Methods

### Option 1: Quick Install (Recommended)

Just run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/cole-robertson/hyprland-keyboard-hotswap/master/web-install-simple.sh | bash
```

### Option 2: Clone and Install

If you prefer to clone the repository first:

```bash
git clone https://github.com/cole-robertson/hyprland-keyboard-hotswap.git
cd hyprland-keyboard-hotswap
chmod +x install-simple.sh
./install-simple.sh
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

### One-Line Installation Issues

If the curl command fails:

```bash
# Download manually and run
wget https://raw.githubusercontent.com/cole-robertson/hyprland-keyboard-hotswap/master/web-install.sh
chmod +x web-install.sh
./web-install.sh
```

Or if you're behind a proxy:

```bash
# Use curl with proxy settings
curl -x proxy:port -fsSL https://raw.githubusercontent.com/cole-robertson/hyprland-keyboard-hotswap/master/web-install.sh | bash
```

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
- curl or wget (for one-line install)
- git (optional, for clone method)
- USB keyboard connected during setup

## License

MIT License - Feel free to modify and distribute as needed.

## Author

Created by Cole Robertson - initially for Flow84@Lofree keyboard, now supports any USB keyboard with interactive configuration.
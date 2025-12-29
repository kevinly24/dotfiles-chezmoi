#!/bin/bash

# Kanata LaunchDaemon Setup Script
set -e

echo "Kanata LaunchDaemon Setup"
echo "========================="

# Get config file path from user
read -p "Enter the full path to your Kanata config file: " CONFIG_FILE

# Validate config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file '$CONFIG_FILE' does not exist!"
    exit 1
fi

echo "Using config file: $CONFIG_FILE"
echo

# Check if executables exist
echo "Checking required executables..."
KANATA_BIN="/opt/homebrew/bin/kanata"
VHID_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
VHID_MANAGER="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"

if [[ ! -f "$KANATA_BIN" ]]; then
    echo "Error: Kanata not found at $KANATA_BIN"
    echo "Install with: brew install kanata"
    exit 1
fi

if [[ ! -f "$VHID_DAEMON" ]]; then
    echo "Error: Karabiner VirtualHIDDevice Daemon not found"
    echo "Install Karabiner-DriverKit-VirtualHIDDevice first"
    exit 1
fi

if [[ ! -f "$VHID_MANAGER" ]]; then
    echo "Error: Karabiner VirtualHIDDevice Manager not found"
    echo "Install Karabiner-DriverKit-VirtualHIDDevice first"
    exit 1
fi

echo "✓ All executables found"
echo

# Check if plist files already exist
echo "Checking existing plist files..."
PLIST_FILES=(
    "/Library/LaunchDaemons/com.example.kanata.plist"
    "/Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist"
    "/Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist"
)

EXISTING_PLISTS=()
for plist in "${PLIST_FILES[@]}"; do
    if [[ -f "$plist" ]]; then
        EXISTING_PLISTS+=("$plist")
    fi
done

if [[ ${#EXISTING_PLISTS[@]} -gt 0 ]]; then
    echo "Warning: Found existing plist files:"
    for plist in "${EXISTING_PLISTS[@]}"; do
        echo "  - $plist"
    done
    read -p "Overwrite existing files? (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script needs sudo privileges to create files in /Library/LaunchDaemons/"
    echo "Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# Create log directory
mkdir -p /Library/Logs/Kanata

# Create kanata.plist
cat > /Library/LaunchDaemons/com.example.kanata.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.kanata</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/kanata</string>
        <string>-c</string>
        <string>$CONFIG_FILE</string>
        <string>--port</string>
        <string>10000</string>
        <string>--debug</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Library/Logs/Kanata/kanata.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Library/Logs/Kanata/kanata.err.log</string>
</dict>
</plist>
EOF

# Create karabiner-vhiddaemon.plist
cat > /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.karabiner-vhiddaemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Create karabiner-vhidmanager.plist
cat > /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.karabiner-vhidmanager</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager</string>
        <string>activate</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

echo "Created LaunchDaemon plist files:"
echo "- /Library/LaunchDaemons/com.example.kanata.plist"
echo "- /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist"
echo "- /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist"
echo

# Bootstrap and enable services
echo "Bootstrapping and enabling services..."
launchctl bootstrap system /Library/LaunchDaemons/com.example.kanata.plist
launchctl enable system/com.example.kanata.plist

launchctl bootstrap system /Library/LaunchDaemons/com.example.karabiner-vhiddaemon.plist
launchctl enable system/com.example.karabiner-vhiddaemon.plist

launchctl bootstrap system /Library/LaunchDaemons/com.example.karabiner-vhidmanager.plist
launchctl enable system/com.example.karabiner-vhidmanager.plist

echo "Setup complete!"
echo
echo "To start services now:"
echo "  sudo launchctl start com.example.kanata"
echo "  sudo launchctl start com.example.karabiner-vhiddaemon"
echo "  sudo launchctl start com.example.karabiner-vhidmanager"
echo
echo "Services will start automatically on reboot."

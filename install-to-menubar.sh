#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.markwilkinson.claude-clipboard-sanitizer"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "Building..."
swiftc "$DIR/ClipboardSanitizer.swift" -o "$DIR/ClipboardSanitizer"

echo "Installing LaunchAgent..."
cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DIR/ClipboardSanitizer</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "Done. The scissors icon should appear in your menu bar."

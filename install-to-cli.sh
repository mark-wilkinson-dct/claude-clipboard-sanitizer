#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-$HOME/bin}"
TARGET="$INSTALL_DIR/sanitize-clipboard"

PYTHON=$(command -v python3 2>/dev/null)
if [ -z "$PYTHON" ]; then
    echo "Error: python3 not found. Install it via 'xcode-select --install' or Homebrew."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

cat > "$TARGET" << EOF
#!/bin/bash
pbpaste | "$PYTHON" "$DIR/sanitize-clipboard.py" | pbcopy && osascript -e 'display notification "Done" with title "Clipboard Sanitized"'
EOF

chmod +x "$TARGET"

echo "Installed to $TARGET"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Note: $INSTALL_DIR is not on your PATH. Add this to your shell profile:"
    echo "  export PATH=\"\$HOME/bin:\$PATH\""
fi

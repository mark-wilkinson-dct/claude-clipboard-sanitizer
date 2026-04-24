# Claude Code Clipboard Sanitizer

A macOS utility that cleans up text copied from the Claude Code CLI.

When you copy Claude's terminal output, you get hard line-breaks at the terminal width, trailing whitespace on every line, and Claude-specific UI characters (`⏺`, `⎿`). This tool strips all of that so the text pastes cleanly into editors, tickets, Slack, etc.

## What it fixes

- Hard line-wraps collapsed into flowing prose
- Trailing whitespace stripped from every line
- Claude Code UI characters (`⏺`, `⎿`) removed
- Non-breaking spaces normalised to regular spaces
- Code blocks, lists, and indented content preserved as-is

## Requirements

- macOS 11 or later
- Python 3.9 or later (ships with macOS via Xcode Command Line Tools)
- Xcode Command Line Tools — `xcode-select --install` (menu bar option only)

## Install

```bash
git clone <repo-url>
cd claude-clipboard-sanitiser
```

### Option A: Menu bar app (recommended)

```bash
./install-to-menubar.sh
```

A scissors icon (✂) appears in your menu bar. **Left-click** to sanitize the clipboard. **Right-click** to open the menu, which has:

- **Show notification on complete** — toggleable (on by default); shows a macOS notification each time the clipboard is sanitized
- **Quit**

The app auto-starts on login.

### Option B: CLI tool

```bash
./install-to-cli.sh
```

Installs a `sanitize-clipboard` command to `~/bin` (pass a different directory as the first argument if you prefer). Run it after copying from Claude:

```bash
sanitize-clipboard
```

## Uninstall

### Menu bar app

```bash
launchctl unload ~/Library/LaunchAgents/com.markwilkinson.claude-clipboard-sanitizer.plist
rm ~/Library/LaunchAgents/com.markwilkinson.claude-clipboard-sanitizer.plist
```

### CLI tool

```bash
rm ~/bin/sanitize-clipboard
```

Then delete the cloned directory.

## Updating

Changes to `sanitize-clipboard.py` take effect immediately — the Python script is invoked fresh on every click.

Changes to `ClipboardSanitizer.swift` require a recompile and relaunch. The easiest way is to re-run the install script, which handles both:

```bash
./install-to-menubar.sh
```

## Restarting the menu bar app

If you quit via right-click, the app won't auto-restart until your next login. To bring it back immediately:

```bash
~/path/to/claude-clipboard-sanitiser/ClipboardSanitizer &
```

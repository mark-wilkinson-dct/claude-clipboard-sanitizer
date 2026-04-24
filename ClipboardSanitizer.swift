import Cocoa
import Darwin

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    private var showNotification: Bool {
        get { UserDefaults.standard.bool(forKey: "showNotification") }
        set { UserDefaults.standard.set(newValue, forKey: "showNotification") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["showNotification": true])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Sanitize Clipboard")
            button.toolTip = "Sanitize Clipboard"
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()

            let titleItem = NSMenuItem(title: "Claude Code Clipboard Sanitizer", action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)

            menu.addItem(NSMenuItem.separator())

            let notifyItem = NSMenuItem(
                title: "Show notification on complete",
                action: #selector(toggleNotification),
                keyEquivalent: ""
            )
            notifyItem.state = showNotification ? .on : .off
            notifyItem.target = self
            menu.addItem(notifyItem)

            menu.addItem(NSMenuItem.separator())

            menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")

            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        } else {
            sanitizeClipboard()
        }
    }

    @objc private func toggleNotification() {
        showNotification.toggle()
    }

    @objc private func sanitizeClipboard() {
        guard let input = NSPasteboard.general.string(forType: .string), !input.isEmpty else { return }

        var size: UInt32 = 4096
        var buffer = [CChar](repeating: 0, count: Int(size))
        if _NSGetExecutablePath(&buffer, &size) != 0 {
            buffer = [CChar](repeating: 0, count: Int(size))
            _NSGetExecutablePath(&buffer, &size)
        }
        let script = URL(fileURLWithPath: String(cString: buffer))
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
            .appendingPathComponent("sanitize-clipboard.py")
            .path

        let python = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]
            .first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/python3"

        let shouldNotify = showNotification

        DispatchQueue.global().async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: python)
            task.arguments = [script]

            let stdin = Pipe()
            let stdout = Pipe()
            task.standardInput = stdin
            task.standardOutput = stdout

            do {
                try task.run()
            } catch {
                return
            }

            stdin.fileHandleForWriting.write(input.data(using: .utf8) ?? Data())
            stdin.fileHandleForWriting.closeFile()
            task.waitUntilExit()

            let output = stdout.fileHandleForReading.readDataToEndOfFile()
            guard let result = String(data: output, encoding: .utf8), !result.isEmpty else { return }

            DispatchQueue.main.async {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result, forType: .string)

                if shouldNotify {
                    let notify = Process()
                    notify.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                    notify.arguments = ["-e", "display notification \"Done\" with title \"Clipboard Sanitized\""]
                    try? notify.run()
                }
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()

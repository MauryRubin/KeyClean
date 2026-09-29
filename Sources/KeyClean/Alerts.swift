import AppKit

/// Alerts for a menu bar app, which has no window to attach them to.
@MainActor
enum Alerts {
    static func error(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

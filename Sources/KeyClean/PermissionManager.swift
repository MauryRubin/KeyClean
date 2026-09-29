import AppKit
import ApplicationServices

/// Accessibility permission: check, ask macOS to list the app, or explain and deep-link.
struct PermissionManager {
    private static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    var isTrusted: Bool { AXIsProcessTrusted() }

    /// Asks macOS to show its own prompt, which also adds KeyClean to the Accessibility list.
    func requestSystemPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @MainActor
    func presentPermissionAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Accessibility access needed"
        alert.informativeText = "KeyClean needs Accessibility access to block keyboard input while you clean. "
            + "Grant access in System Settings → Privacy & Security → Accessibility, then try again."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(Self.settingsURL)
        }
    }
}

import AppKit
import KeyCleanCore

/// Owns the menu bar icon and menu, and renders them from the real lock state.
@MainActor
final class StatusMenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let locker: KeyboardLocker
    private let permissions: PermissionManager
    private let loginItem: LoginItemManager

    init(locker: KeyboardLocker, permissions: PermissionManager, loginItem: LoginItemManager) {
        self.locker = locker
        self.permissions = permissions
        self.loginItem = loginItem
        super.init()
        render()
    }

    private var currentState: LockState { locker.isLocked ? .locked : .unlocked }

    private func render() {
        let state = currentState
        let icon = makeIcon(for: state)
        statusItem.button?.image = icon
        statusItem.button?.title = icon == nil ? (state == .locked ? "🔒" : "⌨") : ""
        statusItem.menu = makeMenu(for: state)
    }

    private func makeIcon(for state: LockState) -> NSImage? {
        let base = NSImage(
            systemSymbolName: state.statusSymbolName,
            accessibilityDescription: state.statusAccessibilityLabel
        )
        switch state {
        case .unlocked:
            base?.isTemplate = true
            return base
        case .locked:
            let red = NSImage.SymbolConfiguration(paletteColors: [.systemRed])
            let tinted = base?.withSymbolConfiguration(red)
            tinted?.isTemplate = false
            return tinted
        }
    }

    private func makeMenu(for state: LockState) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem(state.toggleMenuTitle, action: #selector(toggleLock)))

        if state.showsLaunchAtLogin {
            menu.addItem(.separator())
            let login = menuItem("Launch at Login", action: #selector(toggleLoginItem))
            login.state = loginItem.isEnabled ? .on : .off
            menu.addItem(login)
        }

        menu.addItem(.separator())
        menu.addItem(menuItem(state.quitMenuTitle, action: #selector(quit)))
        return menu
    }

    private func menuItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func toggleLock() {
        if locker.isLocked {
            locker.unlock()
        } else {
            attemptLock()
        }
        render()
    }

    private func attemptLock() {
        do {
            try locker.lock()
        } catch LockError.permissionDenied {
            permissions.presentPermissionAlert()
        } catch {
            Alerts.error(
                title: "Couldn't lock the keyboard",
                message: "The system refused the event tap. Try quitting and reopening KeyClean."
            )
        }
    }

    @objc private func toggleLoginItem() {
        do {
            try loginItem.setEnabled(!loginItem.isEnabled)
        } catch {
            Alerts.error(title: "Couldn't change Launch at Login", message: error.localizedDescription)
        }
        render()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

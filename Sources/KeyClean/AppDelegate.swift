import AppKit
import KeyCleanCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var locker: KeyboardLocker?
    private var menuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let permissions = PermissionManager()
        let locker = KeyboardLocker(driver: SystemEventTap(), isTrusted: { permissions.isTrusted })
        self.locker = locker
        menuController = StatusMenuController(
            locker: locker,
            permissions: permissions,
            loginItem: LoginItemManager()
        )

        if !permissions.isTrusted {
            permissions.requestSystemPrompt()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        locker?.unlock()
    }
}

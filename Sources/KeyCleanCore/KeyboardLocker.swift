public enum LockError: Error, Equatable {
    case permissionDenied
    case tapCreationFailed
}

/// The thing that actually intercepts keyboard events. The real one wraps a
/// CGEventTap; tests use a fake so no system permission is needed.
public protocol EventTapDriver: AnyObject {
    /// True while a tap exists and is intercepting events.
    var isInstalled: Bool { get }
    /// Creates and enables the tap. Returns false if the system refused.
    func install() -> Bool
    func uninstall()
}

/// Locks and unlocks the keyboard by installing and removing the tap.
public final class KeyboardLocker {
    private let driver: EventTapDriver
    private let isTrusted: () -> Bool

    public init(driver: EventTapDriver, isTrusted: @escaping () -> Bool) {
        self.driver = driver
        self.isTrusted = isTrusted
    }

    /// Reads the driver so the UI can never claim "locked" when keys still work.
    public var isLocked: Bool { driver.isInstalled }

    public func lock() throws {
        guard !driver.isInstalled else { return }
        guard isTrusted() else { throw LockError.permissionDenied }
        guard driver.install() else { throw LockError.tapCreationFailed }
    }

    public func unlock() {
        guard driver.isInstalled else { return }
        driver.uninstall()
    }
}

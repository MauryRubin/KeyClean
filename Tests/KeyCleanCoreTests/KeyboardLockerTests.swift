import Testing
@testable import KeyCleanCore

private final class FakeDriver: EventTapDriver {
    var installSucceeds = true
    private(set) var installCount = 0
    private(set) var uninstallCount = 0
    private(set) var isInstalled = false

    func install() -> Bool {
        installCount += 1
        isInstalled = installSucceeds
        return installSucceeds
    }

    func uninstall() {
        uninstallCount += 1
        isInstalled = false
    }

    /// Simulates the system tearing the tap down behind our back.
    func simulateExternalRemoval() { isInstalled = false }
}

struct KeyboardLockerTests {
    private func makeLocker(trusted: Bool = true, driver: FakeDriver = FakeDriver()) -> (KeyboardLocker, FakeDriver) {
        (KeyboardLocker(driver: driver, isTrusted: { trusted }), driver)
    }

    @Test func startsUnlocked() {
        let (locker, _) = makeLocker()
        #expect(!locker.isLocked)
    }

    @Test func lockInstallsTheTap() throws {
        let (locker, driver) = makeLocker()
        try locker.lock()
        #expect(locker.isLocked)
        #expect(driver.installCount == 1)
    }

    @Test func lockWithoutPermissionThrowsAndDoesNotInstall() {
        let (locker, driver) = makeLocker(trusted: false)
        #expect(throws: LockError.permissionDenied) { try locker.lock() }
        #expect(!locker.isLocked)
        #expect(driver.installCount == 0)
    }

    @Test func lockThrowsWhenTapCannotBeCreated() {
        let driver = FakeDriver()
        driver.installSucceeds = false
        let (locker, _) = makeLocker(driver: driver)
        #expect(throws: LockError.tapCreationFailed) { try locker.lock() }
        #expect(!locker.isLocked)
    }

    @Test func lockingTwiceInstallsOnlyOnce() throws {
        let (locker, driver) = makeLocker()
        try locker.lock()
        try locker.lock()
        #expect(driver.installCount == 1)
    }

    @Test func unlockUninstallsTheTap() throws {
        let (locker, driver) = makeLocker()
        try locker.lock()
        locker.unlock()
        #expect(!locker.isLocked)
        #expect(driver.uninstallCount == 1)
    }

    @Test func unlockWhenNotLockedDoesNothing() {
        let (locker, driver) = makeLocker()
        locker.unlock()
        #expect(driver.uninstallCount == 0)
    }

    @Test func isLockedReflectsTheRealTapState() throws {
        let (locker, driver) = makeLocker()
        try locker.lock()
        driver.simulateExternalRemoval()
        #expect(!locker.isLocked)
    }
}

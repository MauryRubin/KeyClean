import Testing
@testable import KeyCleanCore

struct LockStateTests {
    @Test func toggledFlipsBetweenStates() {
        #expect(LockState.unlocked.toggled == .locked)
        #expect(LockState.locked.toggled == .unlocked)
    }

    @Test func toggleMenuTitleNamesTheNextAction() {
        #expect(LockState.unlocked.toggleMenuTitle == "Lock Keyboard")
        #expect(LockState.locked.toggleMenuTitle == "Unlock Keyboard")
    }

    @Test func quitTitleWarnsThatQuittingUnlocks() {
        #expect(LockState.unlocked.quitMenuTitle == "Quit KeyClean")
        #expect(LockState.locked.quitMenuTitle == "Quit KeyClean (Unlocks Keyboard)")
    }

    @Test func statusSymbolMatchesState() {
        #expect(LockState.unlocked.statusSymbolName == "keyboard")
        #expect(LockState.locked.statusSymbolName == "lock.fill")
    }

    @Test func accessibilityLabelMatchesState() {
        #expect(LockState.unlocked.statusAccessibilityLabel == "KeyClean: keyboard unlocked")
        #expect(LockState.locked.statusAccessibilityLabel == "KeyClean: keyboard locked")
    }

    @Test func launchAtLoginOnlyShownWhenUnlocked() {
        #expect(LockState.unlocked.showsLaunchAtLogin)
        #expect(!LockState.locked.showsLaunchAtLogin)
    }
}

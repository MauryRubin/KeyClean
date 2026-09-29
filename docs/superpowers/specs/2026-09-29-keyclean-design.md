# KeyClean — PRD & Design Spec

**Date:** 2026-09-29
**Status:** Draft, awaiting review
**Target machine:** MacBook Air (M1), macOS 15.6.1, Swift 6.2 Command Line Tools (no full Xcode)

---

## 1. Problem

Wiping down a MacBook keyboard presses keys. That types characters, triggers shortcuts, changes brightness and volume, and can do real damage (⌘Q, ⌘W, sending half-finished messages). Today the only safe option is to shut the machine down or put it to sleep.

## 2. Goal

A tiny menu bar app that locks the keyboard with one click. You can wipe it freely, then unlock it with one trackpad click.

### Success criteria

1. While locked, pressing any key (letters, numbers, modifiers, ⌘-shortcuts, the top row's brightness/volume/media keys) has **no effect** in any app.
2. Unlocking takes a single trackpad interaction on the menu bar icon, and the keyboard works again immediately.
3. The lock state is obvious at a glance from the menu bar icon.
4. You can never get stuck: the trackpad always works, and quitting the app always unlocks.
5. If Launch at Login is enabled, the app is in the menu bar after every restart with no manual steps.

### Non-goals (v1)

- Locking the trackpad or mouse
- Timers, auto-unlock, or safety timeouts
- Global keyboard shortcut to start the lock
- Sounds, notifications, or a full-screen overlay
- Blocking the power / Touch ID button (the hardware handles it; software can't block it)
- Distribution to other Macs, notarization, App Store, auto-updates

## 3. User experience

### Menu bar icon

| State    | Icon                                    | Meaning                   |
|----------|-----------------------------------------|---------------------------|
| Unlocked | SF Symbol `keyboard` (template, monochrome) | Keyboard works normally |
| Locked   | SF Symbol `lock.fill`, tinted red       | Keyboard input is blocked |

The app has no Dock icon and no main window (`LSUIElement = true`).

### Menu contents

**Unlocked:**
```
Lock Keyboard
─────────────
✓ Launch at Login
─────────────
Quit KeyClean
```

**Locked:**
```
Unlock Keyboard
─────────────
Quit KeyClean   (also unlocks)
```

### Primary flow

1. Click the menu bar icon, then **Lock Keyboard**.
2. The icon turns into a red lock. Every key press is ignored.
3. Wipe the keyboard.
4. Click the red lock icon with the trackpad, then **Unlock Keyboard**.
5. The icon goes back to the keyboard symbol, and typing works again.

### First run and permissions

Blocking keys requires macOS **Accessibility** permission.

- On launch, and again when you choose **Lock Keyboard**, the app checks for the permission.
- If it's missing, the app shows an alert: *"KeyClean needs Accessibility access to block keyboard input while you clean. Grant access in System Settings → Privacy & Security → Accessibility, then try again."* It has two buttons: **Open System Settings** (goes straight to the Accessibility pane) and **Cancel**.
- Without the permission the lock is **not** started, so the icon never shows "locked" unless keys really are blocked.

## 4. Functional requirements

| ID  | Requirement |
|-----|-------------|
| F1  | The app runs as a menu bar–only app (no Dock icon, no windows except alerts). |
| F2  | **Lock Keyboard** installs a system-wide keyboard event tap that drops all keyboard events. |
| F3  | Blocked event types: `keyDown`, `keyUp`, `flagsChanged`, and system-defined events (type 14: brightness, volume, media, keyboard backlight keys). |
| F4  | All mouse and trackpad events pass through untouched. |
| F5  | **Unlock Keyboard** removes the event tap; keyboard input resumes right away. |
| F6  | The icon and menu always reflect the real tap state (locked only if the tap is installed and enabled). |
| F7  | If macOS disables the tap while locked (`tapDisabledByTimeout` / `tapDisabledByUserInput`), the app re-enables it right away. |
| F8  | Quitting the app while locked removes the tap before exit, and the keyboard works again. |
| F9  | If the tap can't be created (missing permission or a system error), the app stays unlocked and shows the permission alert (or an error alert with the reason). It never fails silently. |
| F10 | **Launch at Login** toggles registration through `SMAppService.mainApp`. The checkmark shows the actual registration status. Failures show an alert. |
| F11 | Launch at Login is **off** by default. You turn it on from the menu. |
| F12 | The app always starts **unlocked**, including when launched at login. |

## 5. Architecture

A Swift Package Manager executable, wrapped into a `.app` bundle by a build script. Each file has one job:

```
KeyClean/
├── Package.swift
├── Sources/
│   ├── KeyCleanCore/               # testable logic, no AppKit UI
│   │   ├── EventFilter.swift       # pure: event type → .block / .pass
│   │   ├── LockState.swift         # enum + pure transition rules
│   │   └── KeyboardLocker.swift    # owns the CGEventTap lifecycle
│   └── KeyClean/                   # app shell
│       ├── main.swift              # NSApplication bootstrap
│       ├── AppDelegate.swift       # wires components, handles terminate
│       ├── StatusMenuController.swift  # icon + menu, renders LockState
│       ├── PermissionManager.swift # AX trust check + alert + open Settings
│       └── LoginItemManager.swift  # SMAppService wrapper
├── Tests/
│   └── KeyCleanCoreTests/          # Swift Testing (`import Testing`)
├── Resources/
│   └── Info.plist                  # LSUIElement, bundle id, version
├── build.sh                        # build → bundle → ad-hoc sign → install
└── README.md
```

### Components

**`EventFilter`** (pure)
- `static func decision(for type: CGEventType) -> FilterDecision`. It returns `.block` for keyboard and system-defined events and `.pass` for everything else.
- It has no side effects and is fully unit-tested.

**`LockState`** (pure)
- `enum LockState { case unlocked, locked }`.
- Transition helpers that return a new state (they never change existing state), plus the menu text and icon name for each state.

**`KeyboardLocker`**
- `func lock() throws(LockError)` creates the tap with `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, ...)`, adds it to the main run loop, and enables it.
- `func unlock()` disables the tap, removes the run loop source, and releases both.
- The tap callback asks `EventFilter` what to do: it returns `nil` to drop an event and returns the event unchanged to let it through. When it receives a tap-disabled event, it re-enables the tap.
- It exposes `isLocked` from the real tap state. `LockError` has the cases `.permissionDenied` and `.tapCreationFailed`.

**`StatusMenuController`**
- Owns the `NSStatusItem` and rebuilds the menu and icon from the current `LockState`.
- Calls `KeyboardLocker` and `PermissionManager`. It holds no blocking logic of its own.

**`PermissionManager`**
- `isTrusted` wraps `AXIsProcessTrusted()`. `requestIfNeeded()` shows the alert and opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.

**`LoginItemManager`**
- `isEnabled` comes from `SMAppService.mainApp.status == .enabled`, and `setEnabled(_:) throws` registers or unregisters the app.

**`AppDelegate`**
- `applicationWillTerminate` calls `keyboardLocker.unlock()` (the safety net for F8).

### Data flow

```
Menu click ─▶ StatusMenuController ─▶ PermissionManager.isTrusted?
                     │                     └─ no ─▶ alert, stay unlocked
                     ▼ yes
              KeyboardLocker.lock() ─▶ CGEventTap(callback → EventFilter)
                     │
                     ▼
              new LockState(.locked) ─▶ re-render icon + menu
```

## 6. Error handling

| Situation | Behavior |
|-----------|----------|
| Accessibility not granted | Stay unlocked, show the permission alert with **Open System Settings** |
| `tapCreate` returns nil despite permission | Stay unlocked, show *"Couldn't lock the keyboard (system refused the event tap). Try quitting and reopening KeyClean."* and log details with `os.Logger` |
| macOS disables the tap mid-lock | Re-enable it in the callback and log it |
| Launch at Login register/unregister fails | Show an alert with the system's error message, and keep the checkmark matching the real status |
| App quits or crashes while locked | On quit: `applicationWillTerminate` unlocks. On a crash: the tap belongs to the process, so macOS removes it when the process dies and the keyboard comes back |

Logging uses `os.Logger` (subsystem `com.sydneymalek.KeyClean`) and can be viewed in Console.app.

## 7. Build, signing & install

- `build.sh`:
  1. Runs `swift build -c release`.
  2. Assembles `KeyClean.app/Contents/{MacOS,Resources,Info.plist}`.
  3. Signs ad hoc with `codesign --force --sign - KeyClean.app`.
  4. Copies the app to `~/Applications/KeyClean.app`.
- Bundle ID: `com.sydneymalek.KeyClean`. Minimum OS: macOS 13 (needed for `SMAppService`).
- **Known quirk:** with ad-hoc signing, macOS may treat each rebuild as a new app and ask for Accessibility permission again. The README explains how to remove the old entry and grant access again. This doesn't affect normal use once you stop rebuilding.

## 8. Testing

**Automated (Swift Testing, `swift test`)**, covering `KeyCleanCore`:
- `EventFilter`: every keyboard and system-defined type returns `.block`. Mouse, trackpad, scroll, and tap-disabled types return `.pass`.
- `LockState`: transitions, menu titles, and icon names for each state.
- `KeyboardLocker`: lock and unlock are safe to call twice, and unlock without a lock does nothing. The tap is injected behind a small protocol so these tests don't need real system permission.
- Goal: ≥80% line coverage of `KeyCleanCore`.

**Manual acceptance checklist** (on the real machine):
- [ ] Fresh install without permission → Lock shows the permission alert, and the icon stays unlocked
- [ ] Grant permission → Lock → the icon turns into a red lock
- [ ] While locked: typing in TextEdit does nothing
- [ ] While locked: ⌘Q, ⌘W, ⌘Tab, and ⌘Space do nothing
- [ ] While locked: brightness, volume, media, and backlight keys do nothing
- [ ] While locked: the trackpad moves and clicks normally
- [ ] Unlock → typing works right away
- [ ] Quit while locked → typing works
- [ ] Turn on Launch at Login → restart → the icon is present and unlocked
- [ ] Turn off Launch at Login → restart → the app doesn't launch

## 9. Known limitations

- The power / Touch ID button can't be blocked.
- The Caps Lock LED may still toggle even though the Caps Lock change is blocked.
- Secure input fields (e.g., password prompts that turn on Secure Event Input) may bypass the event tap. Lock the keyboard while an ordinary app is in front.

## 10. Open questions

None. Unlock method (trackpad click on the menu bar icon), trackpad behavior (stays active), and extras (Launch at Login only) were all decided during brainstorming.

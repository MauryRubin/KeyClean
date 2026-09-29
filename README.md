# KeyClean

KeyClean is a macOS menu bar app that locks your keyboard so you can wipe it
clean without typing anything by accident. The trackpad and mouse keep working,
so you can unlock from the menu when you are done. It has no Dock icon and no
main window.

The menu bar icon shows the state:

- **Unlocked:** the `keyboard` symbol, monochrome. Typing works normally.
- **Locked:** the `lock.fill` symbol, tinted red. Keyboard input is blocked.

## Build and install

```sh
./build.sh
open ~/Applications/KeyClean.app
```

`build.sh` builds a release binary, wraps it in an app bundle, signs it ad hoc,
and installs it to `~/Applications/KeyClean.app`. Requires macOS 13 or later
and the Xcode Command Line Tools.

## First run

KeyClean needs Accessibility permission to block keys. Grant it in
System Settings → Privacy & Security → Accessibility. If the lock still fails
even though KeyClean is enabled there, also enable it under **Input
Monitoring**.

## After a rebuild

Because the app is signed ad hoc, macOS may ask for permission again after a
rebuild. Fix: in that Accessibility list, select the KeyClean entry and remove
it with the minus button, then run the app and grant it again.

## Running tests

```sh
./test.sh
```

Use `./test.sh` instead of plain `swift test`. The Command Line Tools ship
Swift Testing outside the default search path, and the script adds the
framework flags it needs.

## Known limitations

- The power / Touch ID button can't be blocked.
- The Caps Lock LED may still toggle even though the Caps Lock change is blocked.
- Secure input fields (e.g., password prompts that turn on Secure Event Input) may bypass the event tap. Lock the keyboard while an ordinary app is in front.

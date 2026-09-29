/// Whether the keyboard is currently locked, plus the UI strings for each state.
public enum LockState: Equatable {
    case unlocked
    case locked

    public var toggled: LockState {
        switch self {
        case .unlocked: return .locked
        case .locked: return .unlocked
        }
    }

    public var toggleMenuTitle: String {
        switch self {
        case .unlocked: return "Lock Keyboard"
        case .locked: return "Unlock Keyboard"
        }
    }

    public var quitMenuTitle: String {
        switch self {
        case .unlocked: return "Quit KeyClean"
        case .locked: return "Quit KeyClean (Unlocks Keyboard)"
        }
    }

    public var statusSymbolName: String {
        switch self {
        case .unlocked: return "keyboard"
        case .locked: return "lock.fill"
        }
    }

    public var statusAccessibilityLabel: String {
        switch self {
        case .unlocked: return "KeyClean: keyboard unlocked"
        case .locked: return "KeyClean: keyboard locked"
        }
    }

    public var showsLaunchAtLogin: Bool {
        self == .unlocked
    }
}

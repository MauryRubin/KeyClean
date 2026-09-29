import CoreGraphics

/// Decides which events the keyboard lock swallows. Pure and side-effect free.
public enum EventFilter {
    /// NX_SYSDEFINED: brightness, volume, media and keyboard-backlight keys.
    public static let systemDefinedRawValue: UInt32 = 14

    /// Raw event types that are blocked while locked.
    public static let blockedRawValues: Set<UInt32> = [
        CGEventType.keyDown.rawValue,
        CGEventType.keyUp.rawValue,
        CGEventType.flagsChanged.rawValue,
        systemDefinedRawValue,
    ]

    public static func decision(for type: CGEventType) -> FilterDecision {
        blockedRawValues.contains(type.rawValue) ? .block : .pass
    }

    /// macOS sends these instead of a real event when it switches a tap off.
    public static func isTapDisabled(_ type: CGEventType) -> Bool {
        type == .tapDisabledByTimeout || type == .tapDisabledByUserInput
    }
}

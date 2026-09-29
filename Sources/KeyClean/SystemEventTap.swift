import CoreGraphics
import Foundation
import KeyCleanCore
import os

/// The real event tap. Drops keyboard events for the whole login session.
final class SystemEventTap: EventTapDriver {
    private static let log = Logger(subsystem: "com.sydneymalek.KeyClean", category: "tap")

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    var isInstalled: Bool { tap != nil }

    deinit { uninstall() }

    func install() -> Bool {
        guard tap == nil else { return true }

        let mask = EventFilter.blockedRawValues.reduce(CGEventMask(0)) { mask, raw in
            mask | (CGEventMask(1) << CGEventMask(raw))
        }
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: tapCallback,
            userInfo: userInfo
        ) else {
            Self.log.error("CGEvent.tapCreate returned nil (permission missing or system refused)")
            return false
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)

        tap = port
        source = runLoopSource
        Self.log.info("Keyboard locked")
        return true
    }

    func uninstall() {
        guard let port = tap else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CFMachPortInvalidate(port)
        tap = nil
        source = nil
        Self.log.info("Keyboard unlocked")
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if EventFilter.isTapDisabled(type) {
            Self.log.error("Tap disabled by system (type \(type.rawValue)); re-enabling")
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
                if !CGEvent.tapIsEnabled(tap: tap) {
                    Self.log.error("Re-enabling tap failed")
                }
            }
            return Unmanaged.passUnretained(event)
        }
        switch EventFilter.decision(for: type) {
        case .block: return nil
        case .pass: return Unmanaged.passUnretained(event)
        }
    }
}

private let tapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let driver = Unmanaged<SystemEventTap>.fromOpaque(userInfo).takeUnretainedValue()
    return driver.handle(type: type, event: event)
}

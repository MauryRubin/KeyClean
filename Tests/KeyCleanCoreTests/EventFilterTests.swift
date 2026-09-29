import CoreGraphics
import Testing
@testable import KeyCleanCore

struct EventFilterTests {
    @Test func blocksKeyboardEvents() {
        for type in [CGEventType.keyDown, .keyUp, .flagsChanged] {
            #expect(EventFilter.decision(for: type) == .block, "\(type) should be blocked")
        }
    }

    @Test func blocksSystemDefinedEvents() throws {
        // Brightness, volume, media and backlight keys arrive as NX_SYSDEFINED (14).
        let systemDefined = try #require(CGEventType(rawValue: 14))
        #expect(EventFilter.decision(for: systemDefined) == .block)
    }

    @Test func passesMouseAndTrackpadEvents() {
        let types: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .scrollWheel,
        ]
        for type in types {
            #expect(EventFilter.decision(for: type) == .pass, "\(type) should pass")
        }
    }

    @Test func detectsTapDisabledEvents() {
        #expect(EventFilter.isTapDisabled(.tapDisabledByTimeout))
        #expect(EventFilter.isTapDisabled(.tapDisabledByUserInput))
        #expect(!EventFilter.isTapDisabled(.keyDown))
    }

    @Test func tapDisabledEventsAreNotBlocked() {
        #expect(EventFilter.decision(for: .tapDisabledByTimeout) == .pass)
        #expect(EventFilter.decision(for: .tapDisabledByUserInput) == .pass)
    }
}

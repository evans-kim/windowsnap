import XCTest
import Carbon
@testable import SnapCore

final class ShortcutTests: XCTestCase {
    func testDefaultsAndDuplicateDetection() {
        var config = ShortcutConfiguration.defaults
        XCTAssertNil(config.validationError)
        XCTAssertEqual(config.bindings[Direction.left.rawValue]?.label, "⌥⌘ ←")
        config.bindings[Direction.right.rawValue] = config.bindings[Direction.left.rawValue]
        XCTAssertNotNil(config.validationError)
    }

    func testRejectsMissingUnknownAndUnmodifiedKeys() {
        var config = ShortcutConfiguration.defaults
        config.bindings.removeValue(forKey: Direction.up.rawValue)
        XCTAssertNotNil(config.validationError)
        config = .defaults
        config.bindings[Direction.left.rawValue]?.modifiers = UInt32(shiftKey)
        XCTAssertNotNil(config.validationError)
        config.bindings[Direction.left.rawValue]?.modifiers = UInt32(controlKey)
        XCTAssertNil(config.validationError)
        config.bindings[Direction.left.rawValue]?.keyCode = 9999
        XCTAssertNotNil(config.validationError)
    }

    func testPersistenceAndCorruptDataFallback() throws {
        let suite = "WindowSnapTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var config = ShortcutConfiguration.defaults
        config.bindings[Direction.left.rawValue] = Shortcut(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(controlKey | optionKey))
        config.save(to: defaults)
        XCTAssertEqual(ShortcutConfiguration.load(from: defaults), config)
        defaults.set(Data("bad json".utf8), forKey: "shortcuts.v1")
        XCTAssertEqual(ShortcutConfiguration.load(from: defaults), .defaults)
        config.bindings = [:]
        defaults.set(try JSONEncoder().encode(config), forKey: "shortcuts.v1")
        XCTAssertEqual(ShortcutConfiguration.load(from: defaults), .defaults)
    }
}

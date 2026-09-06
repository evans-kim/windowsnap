import XCTest
import CoreGraphics
@testable import SnapCore

final class LayoutTests: XCTestCase {
    func testHorizontalThenUpMaximizesOnlySameWindowWithinInterval() {
        for horizontal in [Direction.left, .right] {
            var sequence = PressSequence()
            sequence.record(direction: horizontal, now: 10)
            XCTAssertTrue(sequence.maximizes(direction: .up, sameWindow: true, now: 10.5))
            XCTAssertFalse(sequence.maximizes(direction: .up, sameWindow: false, now: 10.5))
            XCTAssertFalse(sequence.maximizes(direction: .up, sameWindow: true, now: 10.81))
            XCTAssertFalse(sequence.maximizes(direction: .down, sameWindow: true, now: 10.5))
            XCTAssertFalse(sequence.maximizes(direction: .up, sameWindow: true, now: 9))
            XCTAssertTrue(sequence.usesThirds(direction: horizontal, sameWindow: true, now: 10.5))
            sequence.record(direction: .up, now: 10.5)
            XCTAssertFalse(sequence.maximizes(direction: .up, sameWindow: true, now: 10.7))
            sequence.reset()
            XCTAssertFalse(sequence.maximizes(direction: .up, sameWindow: true, now: 10.7))
        }
    }

    func testDirectionalHalvesAndThirds() {
        let screen = CGRect(x: -1440, y: 25, width: 1440, height: 900)
        for thirds in [false, true] {
            let divisor: CGFloat = thirds ? 3 : 2
            XCTAssertEqual(Layout.frame(in: screen, direction: .left, thirds: thirds), CGRect(x: -1440, y: 25, width: 1440 / divisor, height: 900))
            XCTAssertEqual(Layout.frame(in: screen, direction: .right, thirds: thirds), CGRect(x: -1440 / divisor, y: 25, width: 1440 / divisor, height: 900))
            XCTAssertEqual(Layout.frame(in: screen, direction: .up, thirds: thirds), CGRect(x: -1440, y: 25, width: 1440, height: 900 / divisor))
            XCTAssertEqual(Layout.frame(in: screen, direction: .down, thirds: thirds), CGRect(x: -1440, y: 925 - 900 / divisor, width: 1440, height: 900 / divisor))
        }
    }

    func testScreenCoordinatesIncludeVerticalAndNegativeDisplays() {
        XCTAssertEqual(Layout.accessibilityFrame(CGRect(x: 0, y: 24, width: 1440, height: 851), primaryHeight: 900), CGRect(x: 0, y: 25, width: 1440, height: 851))
        XCTAssertEqual(Layout.accessibilityFrame(CGRect(x: -1920, y: 900, width: 1920, height: 1080), primaryHeight: 900), CGRect(x: -1920, y: -1080, width: 1920, height: 1080))
    }

    func testLargestIntersectionAndOffscreenFallback() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800), CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        XCTAssertEqual(Layout.screenIndex(for: CGRect(x: 900, y: 100, width: 600, height: 400), screens: screens), 1)
        XCTAssertEqual(Layout.screenIndex(for: CGRect(x: -500, y: 100, width: 100, height: 100), screens: screens), 0)
        XCTAssertNil(Layout.screenIndex(for: .zero, screens: []))
    }

    func testRepeatRequiresSameWindowDirectionAndTimeWindow() {
        var sequence = PressSequence()
        XCTAssertFalse(sequence.usesThirds(direction: .left, sameWindow: true, now: 1))
        sequence.record(direction: .left, now: 1)
        XCTAssertTrue(sequence.usesThirds(direction: .left, sameWindow: true, now: 1.5))
        XCTAssertFalse(sequence.usesThirds(direction: .right, sameWindow: true, now: 1.5))
        XCTAssertFalse(sequence.usesThirds(direction: .left, sameWindow: false, now: 1.5))
        XCTAssertFalse(sequence.usesThirds(direction: .left, sameWindow: true, now: 1.81))
        sequence.record(direction: .left, now: 1.5)
        XCTAssertTrue(sequence.usesThirds(direction: .left, sameWindow: true, now: 2))
        sequence.reset()
        XCTAssertFalse(sequence.usesThirds(direction: .left, sameWindow: true, now: 2.1))
    }
}

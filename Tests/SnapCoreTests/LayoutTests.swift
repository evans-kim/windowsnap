import XCTest
import CoreGraphics
@testable import SnapCore

final class LayoutTests: XCTestCase {
    func testPerpendicularDirectionsSelectCornerOnlyForSameWindowWithinInterval() {
        let pairs: [(Direction, Direction, Corner)] = [
            (.up, .left, .upperLeft), (.up, .right, .upperRight),
            (.down, .right, .lowerRight), (.down, .left, .lowerLeft)
        ]
        for (first, second, expected) in pairs {
            for (start, end) in [(first, second), (second, first)] {
                var sequence = PressSequence()
                sequence.record(direction: start, now: 10)
                XCTAssertEqual(sequence.corner(direction: end, sameWindow: true, now: 10.5), expected)
                XCTAssertNil(sequence.corner(direction: end, sameWindow: false, now: 10.5))
                XCTAssertNil(sequence.corner(direction: end, sameWindow: true, now: 10.81))
                XCTAssertNil(sequence.corner(direction: end, sameWindow: true, now: 9))
                XCTAssertNil(sequence.corner(direction: start, sameWindow: true, now: 10.5))
                sequence.reset()
                XCTAssertNil(sequence.corner(direction: end, sameWindow: true, now: 10.5))
            }
        }
        var sequence = PressSequence()
        sequence.record(direction: .left, now: 10)
        XCTAssertNil(sequence.corner(direction: .right, sameWindow: true, now: 10.5))
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

    func testFourCornersUseVisibleScreenBounds() {
        let screen = CGRect(x: -1440, y: 25, width: 1440, height: 900)
        XCTAssertEqual(Layout.frame(in: screen, corner: .upperLeft), CGRect(x: -1440, y: 25, width: 720, height: 450))
        XCTAssertEqual(Layout.frame(in: screen, corner: .upperRight), CGRect(x: -720, y: 25, width: 720, height: 450))
        XCTAssertEqual(Layout.frame(in: screen, corner: .lowerRight), CGRect(x: -720, y: 475, width: 720, height: 450))
        XCTAssertEqual(Layout.frame(in: screen, corner: .lowerLeft), CGRect(x: -1440, y: 475, width: 720, height: 450))
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

import Foundation
import CoreGraphics

public enum Direction: UInt32, CaseIterable {
    case left = 1, right, up, down
}

public enum Layout {
    // All geometry here uses Accessibility's global top-left coordinates.
    public static func frame(in screen: CGRect, direction: Direction, thirds: Bool) -> CGRect {
        let divisor: CGFloat = thirds ? 3 : 2
        switch direction {
        case .left:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width / divisor, height: screen.height)
        case .right:
            let width = screen.width / divisor
            return CGRect(x: screen.maxX - width, y: screen.minY, width: width, height: screen.height)
        case .up:
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: screen.height / divisor)
        case .down:
            let height = screen.height / divisor
            return CGRect(x: screen.minX, y: screen.maxY - height, width: screen.width, height: height)
        }
    }

    public static func accessibilityFrame(_ frame: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: frame.minX, y: primaryHeight - frame.maxY, width: frame.width, height: frame.height)
    }

    public static func screenIndex(for window: CGRect, screens: [CGRect]) -> Int? {
        guard !screens.isEmpty else { return nil }
        return screens.indices.max { a, b in
            let left = window.intersection(screens[a])
            let right = window.intersection(screens[b])
            let la = left.isNull ? 0 : left.width * left.height
            let ra = right.isNull ? 0 : right.width * right.height
            if la != ra { return la < ra }
            func distance(_ screen: CGRect) -> CGFloat {
                let dx = max(screen.minX - window.midX, 0, window.midX - screen.maxX)
                let dy = max(screen.minY - window.midY, 0, window.midY - screen.maxY)
                return dx * dx + dy * dy
            }
            return distance(screens[a]) > distance(screens[b])
        }
    }
}

public struct PressSequence {
    public static let interval: TimeInterval = 0.8
    private var direction: Direction?
    private var timestamp: TimeInterval = -.infinity

    public init() {}

    public func usesThirds(direction: Direction, sameWindow: Bool, now: TimeInterval) -> Bool {
        sameWindow && self.direction == direction && now >= timestamp && now - timestamp <= Self.interval
    }

    public func maximizes(direction: Direction, sameWindow: Bool, now: TimeInterval) -> Bool {
        sameWindow && direction == .up && (self.direction == .left || self.direction == .right)
            && now >= timestamp && now - timestamp <= Self.interval
    }

    public mutating func record(direction: Direction, now: TimeInterval) {
        self.direction = direction
        timestamp = now
    }

    public mutating func reset() { self = PressSequence() }
}

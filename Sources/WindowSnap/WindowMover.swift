import AppKit
import ApplicationServices
import SnapCore

final class WindowMover {
    private enum Request {
        case direction(Direction)
        case maximize
    }

    private var sequence = PressSequence()
    private var previousWindow: AXUIElement?

    func reset() {
        sequence.reset()
        previousWindow = nil
    }

    func snap(_ direction: Direction) -> String { place(.direction(direction)) }

    func maximize() -> String { place(.maximize) }

    private func place(_ request: Request) -> String {
        guard AXIsProcessTrusted() else {
            reset()
            return "현재 실행 파일의 권한을 확인할 수 없습니다. WindowSnap 설정에서 확인해 주세요."
        }
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            reset()
            return "배치할 앱의 창을 먼저 선택해 주세요."
        }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.5)
        guard let rawWindow = attribute(application, kAXFocusedWindowAttribute),
              CFGetTypeID(rawWindow) == AXUIElementGetTypeID() else {
            reset()
            return "활성 창을 찾을 수 없습니다."
        }
        let window = rawWindow as! AXUIElement
        if let fullScreen = attribute(window, "AXFullScreen") as? Bool, fullScreen {
            reset()
            return "전체 화면을 종료한 뒤 사용해 주세요."
        }
        var canMove = DarwinBoolean(false)
        var canResize = DarwinBoolean(false)
        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &canMove)
        AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &canResize)
        guard canMove.boolValue, canResize.boolValue, let current = frame(window) else {
            reset()
            return "이 창은 위치 또는 크기 변경을 지원하지 않습니다."
        }
        let screens = NSScreen.screens
        guard let primary = screens.first else { return "화면을 찾을 수 없습니다." }
        let bounds = screens.map { Layout.accessibilityFrame($0.frame, primaryHeight: primary.frame.height) }
        guard let index = Layout.screenIndex(for: current, screens: bounds) else { return "화면을 찾을 수 없습니다." }
        let visible = Layout.accessibilityFrame(screens[index].visibleFrame, primaryHeight: primary.frame.height)
        let now = ProcessInfo.processInfo.systemUptime
        let sameWindow = previousWindow.map { CFEqual($0, window) } ?? false
        let target: CGRect
        let description: String
        let anchorRight: Bool
        let anchorBottom: Bool
        switch request {
        case .maximize:
            target = visible
            description = "최대화"
            anchorRight = false
            anchorBottom = false
        case .direction(let direction):
            if let corner = sequence.corner(direction: direction, sameWindow: sameWindow, now: now) {
                target = Layout.frame(in: visible, corner: corner)
                description = "1/4"
                anchorRight = corner == .upperRight || corner == .lowerRight
                anchorBottom = corner == .lowerLeft || corner == .lowerRight
            } else {
                let thirds = sequence.usesThirds(direction: direction, sameWindow: sameWindow, now: now)
                target = Layout.frame(in: visible, direction: direction, thirds: thirds)
                description = thirds ? "1/3" : "1/2"
                anchorRight = direction == .right
                anchorBottom = direction == .down
            }
        }
        // Resize before and after moving: some apps constrain size at the old position.
        _ = setSize(window, target.size)
        let moveResult = setPosition(window, target.origin)
        let resizeResult = setSize(window, target.size)
        guard moveResult == .success, resizeResult == .success, let actual = frame(window) else {
            reset()
            return "창 배치에 실패했습니다. 앱의 응답 상태를 확인해 주세요."
        }
        // Respect app minimum size but keep the requested edge inside the display.
        var anchored = target.origin
        if anchorRight { anchored.x = visible.maxX - actual.width }
        if anchorBottom { anchored.y = visible.maxY - actual.height }
        anchored.x = max(visible.minX, anchored.x)
        anchored.y = max(visible.minY, anchored.y)
        guard setPosition(window, anchored) == .success else {
            reset()
            return "창의 최종 위치를 변경할 수 없습니다."
        }
        previousWindow = window
        switch request {
        case .direction(let direction): sequence.record(direction: direction, now: now)
        case .maximize: sequence.reset()
        }
        if abs(actual.width - target.width) > 2 || abs(actual.height - target.height) > 2 {
            return "앱의 창 크기 제한에 맞춰 배치했습니다."
        }
        return "\(app.localizedName ?? "창") · \(description) 배치 완료"
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
        return result
    }

    private func frame(_ window: AXUIElement) -> CGRect? {
        guard let p = attribute(window, kAXPositionAttribute), let s = attribute(window, kAXSizeAttribute),
              CFGetTypeID(p) == AXValueGetTypeID(), CFGetTypeID(s) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(p as! AXValue, .cgPoint, &point), AXValueGetValue(s as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: point, size: size)
    }

    private func setPosition(_ window: AXUIElement, _ point: CGPoint) -> AXError {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return .failure }
        return AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }

    private func setSize(_ window: AXUIElement, _ size: CGSize) -> AXError {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return .failure }
        return AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }
}

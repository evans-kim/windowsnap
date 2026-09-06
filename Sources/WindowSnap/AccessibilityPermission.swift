import AppKit
import ApplicationServices
import Combine

/// Read permission state without opening dialogs or stealing focus from the target app.
final class AccessibilityPermission: ObservableObject {
    @Published private(set) var trusted = AXIsProcessTrusted()
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() { trusted = AXIsProcessTrusted() }

    func openSettings() {
        // Only explicit user actions reach here. Do not also request an AX prompt:
        // the settings page already provides the permission control.
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func revealApp() { NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL]) }

    deinit { timer?.invalidate() }
}

import Foundation
import ServiceManagement

final class LoginLaunch: ObservableObject {
    @Published private(set) var requested = false
    @Published private(set) var statusText = ""
    @Published private(set) var needsApproval = false
    @Published private(set) var error: String?

    init() { refresh() }

    func refresh() {
        let status = SMAppService.mainApp.status
        requested = status == .enabled || status == .requiresApproval
        needsApproval = status == .requiresApproval
        switch status {
        case .enabled: statusText = "켜짐 · 다음 로그인부터 자동 실행됩니다."
        case .requiresApproval: statusText = "승인 대기 · 시스템 설정에서 로그인 항목을 허용해 주세요."
        case .notRegistered: statusText = "꺼짐"
        case .notFound: statusText = "앱을 찾을 수 없습니다. 앱 위치를 확인해 주세요."
        @unknown default: statusText = "자동 실행 상태를 확인할 수 없습니다."
        }
    }

    func setEnabled(_ enabled: Bool) {
        error = nil
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled && SMAppService.mainApp.status != .requiresApproval {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            self.error = "자동 실행 설정 실패: \(error.localizedDescription)"
        }
        refresh()
    }

    func configureInitialDefault() {
        guard !UserDefaults.standard.bool(forKey: "loginLaunch.initialized") else { return }
        setEnabled(true)
        // Do not override a later user choice made in either the app or System Settings.
        UserDefaults.standard.set(true, forKey: "loginLaunch.initialized")
    }

    func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }
}

import AppKit
import ApplicationServices
import SnapCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let hotKeys = HotKeys()
    private let mover = WindowMover()
    private let permissionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let resultItem = NSMenuItem(title: "단축키를 기다리는 중", action: nil, keyEquivalent: "")
    private var enabled = false
    private var configuration = ShortcutConfiguration.load()
    private let loginLaunch = LoginLaunch()
    private let accessibility = AccessibilityPermission()
    private var settingsWindow: SettingsWindow?
    private var shortcutItems: [UInt32: NSMenuItem] = [:]
    private var pauseItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "WindowSnap 창 배치")
        statusItem.button?.toolTip = "WindowSnap · 창 배치"
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "WindowSnap", action: nil, keyEquivalent: ""))
        menu.addItem(permissionItem)
        menu.addItem(resultItem)
        menu.addItem(.separator())
        for direction in Direction.allCases {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            shortcutItems[direction.rawValue] = item
            menu.addItem(item)
        }
        let maximizeItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        shortcutItems[ShortcutConfiguration.maximizeID] = maximizeItem
        menu.addItem(maximizeItem)
        refreshShortcutLabels()
        menu.addItem(NSMenuItem(title: "같은 단축키를 0.8초 안에 다시 누르면 1/3", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "직각 방향을 0.8초 안에 이어 누르면 해당 모서리 1/4", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        add("설정…", action: #selector(showSettings), to: menu)
        add("손쉬운 사용 권한 설정…", action: #selector(openPermissions), to: menu)
        add("사용 방법…", action: #selector(showHelp), to: menu)
        add("단축키 일시 정지", action: #selector(toggle(_:)), to: menu)
        pauseItem = menu.items.last
        menu.addItem(.separator())
        add("WindowSnap 종료", action: #selector(quit), to: menu)
        statusItem.menu = menu
        hotKeys.onPress = { [weak self] direction in
            guard let self else { return }
            let message = self.mover.snap(direction)
            self.resultItem.title = message
            self.statusItem.button?.toolTip = "WindowSnap · \(message)"
            self.refreshPermissions()
        }
        hotKeys.onMaximize = { [weak self] in
            guard let self else { return }
            let message = self.mover.maximize()
            self.resultItem.title = message
            self.statusItem.button?.toolTip = "WindowSnap · \(message)"
            self.refreshPermissions()
        }
        enabled = hotKeys.start(configuration: configuration)
        refreshPauseLabel()
        if !enabled { resultItem.title = "단축키 등록 실패 · 다른 앱의 단축키를 확인하세요" }
        loginLaunch.configureInitialDefault()
        if let error = loginLaunch.error { resultItem.title = error }
        refreshPermissions()
        if !UserDefaults.standard.bool(forKey: "didShowWelcome") {
            showHelp()
            UserDefaults.standard.set(true, forKey: "didShowWelcome")
        }
        if CommandLine.arguments.contains("--settings") || loginLaunch.error != nil {
            showSettings()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func add(_ title: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    func menuWillOpen(_ menu: NSMenu) { refreshPermissions() }

    private func refreshShortcutLabels() {
        for direction in Direction.allCases {
            shortcutItems[direction.rawValue]?.title = "\(configuration.bindings[direction.rawValue]!.label)   \(direction.title) 1/2"
        }
        shortcutItems[ShortcutConfiguration.maximizeID]?.title = "\(configuration.bindings[ShortcutConfiguration.maximizeID]!.label)   최대화"
    }

    private func refreshPauseLabel() {
        pauseItem?.title = enabled ? "단축키 일시 정지" : "단축키 다시 시작"
    }

    @objc private func showSettings() {
        loginLaunch.refresh()
        if settingsWindow == nil {
            let model = SettingsModel(configuration: configuration) { [weak self] candidate in
                guard let self else { return "앱이 실행 중이 아닙니다." }
                return self.applyShortcuts(candidate)
            }
            settingsWindow = SettingsWindow(model: model, login: loginLaunch, accessibility: accessibility)
        }
        settingsWindow?.present()
    }

    private func applyShortcuts(_ candidate: ShortcutConfiguration) -> String? {
        if let error = candidate.validationError { return error }
        let wasEnabled = enabled
        if !hotKeys.start(configuration: candidate) {
            enabled = wasEnabled && hotKeys.start(configuration: configuration)
            refreshPauseLabel()
            if wasEnabled && !enabled {
                resultItem.title = "기존 단축키 복원 실패 · 단축키를 다시 시작해 주세요"
                return "단축키 충돌이 발생했고 기존 단축키도 복원하지 못했습니다. 다른 앱의 단축키를 확인한 뒤 다시 시작해 주세요."
            }
            return "단축키를 등록할 수 없습니다. 다른 앱 또는 macOS 단축키와의 충돌을 확인해 주세요. 기존 설정은 유지됩니다."
        }
        if !wasEnabled { hotKeys.stop() }
        configuration = candidate
        configuration.save()
        mover.reset()
        refreshShortcutLabels()
        resultItem.title = wasEnabled ? "새 단축키가 적용되었습니다." : "단축키 저장됨 · 일시 정지 중"
        return nil
    }

    private func refreshPermissions() {
        accessibility.refresh()
        permissionItem.title = accessibility.trusted ? "● 손쉬운 사용 권한 허용됨" : "○ 현재 앱의 손쉬운 사용 권한 확인 필요"
    }

    @objc private func openPermissions() {
        accessibility.openSettings()
    }

    @objc private func showHelp() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "WindowSnap"
        let shortcuts = Direction.allCases.map { "\(configuration.bindings[$0.rawValue]!.label) : \($0.title) 절반" }.joined(separator: "\n")
        let maximize = configuration.bindings[ShortcutConfiguration.maximizeID]!.label
        alert.informativeText = "활성 창을 설정한 단축키로 배치합니다.\n\n\(shortcuts)\n\(maximize) : 최대화\n같은 단축키를 0.8초 안에 다시 누르면 1/3로 줄어듭니다. 직각 방향키를 0.8초 안에 이어 누르면 해당 모서리 1/4로 배치합니다.\n\n시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 WindowSnap을 허용해 주세요. 허용 후 사용할 앱의 창을 선택하면 바로 작동합니다.\n\n메뉴 막대 → 설정에서 로그인 시 자동 실행과 단축키를 변경할 수 있습니다."
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "권한 설정 열기")
        if alert.runModal() == .alertSecondButtonReturn { openPermissions() }
    }

    @objc private func toggle(_ sender: NSMenuItem) {
        if enabled {
            hotKeys.stop()
            enabled = false
            mover.reset()
            sender.title = "단축키 다시 시작"
            resultItem.title = "단축키 일시 정지됨"
        } else {
            enabled = hotKeys.start(configuration: configuration)
            sender.title = enabled ? "단축키 일시 정지" : "단축키 다시 시작"
            resultItem.title = enabled ? "단축키를 기다리는 중" : "단축키 등록 실패 · 다른 앱의 단축키를 확인하세요"
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

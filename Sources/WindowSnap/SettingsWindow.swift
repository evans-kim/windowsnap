import AppKit
import SwiftUI
import Carbon
import SnapCore

final class SettingsModel: ObservableObject {
    @Published var draft: ShortcutConfiguration
    @Published var message = ""
    @Published var success = false
    let apply: (ShortcutConfiguration) -> String?

    init(configuration: ShortcutConfiguration, apply: @escaping (ShortcutConfiguration) -> String?) {
        draft = configuration
        self.apply = apply
    }

    func save() {
        if let error = draft.validationError ?? apply(draft) {
            message = error
            success = false
        } else {
            message = "단축키 설정을 저장했습니다."
            success = true
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsModel
    @ObservedObject var login: LoginLaunch
    @ObservedObject var accessibility: AccessibilityPermission

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("WindowSnap 설정").font(.title2.bold())
            GroupBox("손쉬운 사용") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(accessibility.trusted ? "허용됨 · 창 배치를 사용할 수 있습니다." : "현재 실행 중인 앱의 권한을 macOS가 허용하지 않고 있습니다.")
                        .font(.callout)
                    if !accessibility.trusted {
                        Text("이미 켜져 있다면 이전 빌드의 권한일 수 있습니다. 손쉬운 사용 목록에서 WindowSnap을 제거하고, 아래 ‘현재 앱 위치’의 앱을 다시 추가한 뒤 허용해 주세요.")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Button("손쉬운 사용 설정…") { accessibility.openSettings() }
                            Button("현재 앱 위치") { accessibility.revealApp() }
                            Button("다시 확인") { accessibility.refresh() }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
            }
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Mac 로그인 시 자동 실행", isOn: Binding(get: { login.requested }, set: { login.setEnabled($0) }))
                    Text(login.statusText).font(.caption).foregroundStyle(.secondary)
                    if let error = login.error { Text(error).font(.caption).foregroundStyle(.red) }
                    Button(login.needsApproval ? "로그인 항목 승인하기…" : "시스템 로그인 항목 설정…") { login.openSystemSettings() }
                    Text("자동 실행 변경은 즉시 적용됩니다.").font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
            }
            Text("방향별 단축키").font(.headline)
            Text("같은 단축키를 0.8초 안에 다시 누르면 1/3, 좌우 배치 후 위쪽을 누르면 최대화합니다.")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(Direction.allCases, id: \.rawValue) { direction in
                HStack(spacing: 12) {
                    Text(direction.title).frame(width: 50, alignment: .leading)
                    modifier("⌃", flag: controlKey, direction: direction)
                    modifier("⌥", flag: optionKey, direction: direction)
                    modifier("⇧", flag: shiftKey, direction: direction)
                    modifier("⌘", flag: cmdKey, direction: direction)
                    Picker("키", selection: Binding(
                        get: { model.draft.bindings[direction.rawValue]!.keyCode },
                        set: { model.draft.bindings[direction.rawValue]!.keyCode = $0 }
                    )) {
                        ForEach(Shortcut.keys, id: \.code) { key in Text(key.label).tag(key.code) }
                    }.labelsHidden().frame(width: 90)
                    Text(model.draft.bindings[direction.rawValue]!.label).font(.system(.body, design: .monospaced))
                }
            }
            Text("문자 키는 영문 키보드의 물리적 위치 기준입니다. ⌘, ⌥, ⌃ 중 하나 이상을 포함하세요.")
                .font(.caption).foregroundStyle(.secondary)
            if let error = model.draft.validationError { Text(error).font(.callout).foregroundStyle(.red) }
            if !model.message.isEmpty {
                Text(model.message).font(.callout).foregroundStyle(model.success ? Color.secondary : Color.red)
            }
            HStack {
                Button("기본 단축키로 복원") { model.draft = .defaults; model.message = "저장을 누르면 기본 단축키가 적용됩니다."; model.success = true }
                Spacer()
                Button("단축키 저장") { model.save() }.keyboardShortcut(.defaultAction)
                    .disabled(model.draft.validationError != nil)
            }
        }
        .padding(24).frame(width: 620)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in login.refresh() }
        .onChange(of: model.draft) { _ in model.message = "" }
    }

    private func modifier(_ title: String, flag: Int, direction: Direction) -> some View {
        Toggle(title, isOn: Binding(
            get: { model.draft.bindings[direction.rawValue]!.modifiers & UInt32(flag) != 0 },
            set: { selected in
                if selected { model.draft.bindings[direction.rawValue]!.modifiers |= UInt32(flag) }
                else { model.draft.bindings[direction.rawValue]!.modifiers &= ~UInt32(flag) }
            }
        )).toggleStyle(.checkbox).help("\(direction.title) \(title) 보조키")
    }
}

final class SettingsWindow: NSWindowController {
    init(model: SettingsModel, login: LoginLaunch, accessibility: AccessibilityPermission) {
        let host = NSHostingView(rootView: SettingsView(model: model, login: login, accessibility: accessibility))
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "WindowSnap 설정"
        window.contentView = host
        window.setContentSize(host.fittingSize)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

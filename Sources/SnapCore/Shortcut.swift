import Foundation
import Carbon

public struct Shortcut: Codable, Equatable, Hashable {
    public var keyCode: UInt32
    public var modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let keys: [(code: UInt32, label: String)] = {
        let entries: [(Int, String)] = [
            (kVK_LeftArrow, "←"), (kVK_RightArrow, "→"), (kVK_UpArrow, "↑"), (kVK_DownArrow, "↓"),
            (kVK_ANSI_A, "A"), (kVK_ANSI_B, "B"), (kVK_ANSI_C, "C"), (kVK_ANSI_D, "D"),
            (kVK_ANSI_E, "E"), (kVK_ANSI_F, "F"), (kVK_ANSI_G, "G"), (kVK_ANSI_H, "H"),
            (kVK_ANSI_I, "I"), (kVK_ANSI_J, "J"), (kVK_ANSI_K, "K"), (kVK_ANSI_L, "L"),
            (kVK_ANSI_M, "M"), (kVK_ANSI_N, "N"), (kVK_ANSI_O, "O"), (kVK_ANSI_P, "P"),
            (kVK_ANSI_Q, "Q"), (kVK_ANSI_R, "R"), (kVK_ANSI_S, "S"), (kVK_ANSI_T, "T"),
            (kVK_ANSI_U, "U"), (kVK_ANSI_V, "V"), (kVK_ANSI_W, "W"), (kVK_ANSI_X, "X"),
            (kVK_ANSI_Y, "Y"), (kVK_ANSI_Z, "Z"), (kVK_ANSI_0, "0"), (kVK_ANSI_1, "1"),
            (kVK_ANSI_2, "2"), (kVK_ANSI_3, "3"), (kVK_ANSI_4, "4"), (kVK_ANSI_5, "5"),
            (kVK_ANSI_6, "6"), (kVK_ANSI_7, "7"), (kVK_ANSI_8, "8"), (kVK_ANSI_9, "9"),
            (kVK_F1, "F1"), (kVK_F2, "F2"), (kVK_F3, "F3"), (kVK_F4, "F4"),
            (kVK_F5, "F5"), (kVK_F6, "F6"), (kVK_F7, "F7"), (kVK_F8, "F8"),
            (kVK_F9, "F9"), (kVK_F10, "F10"), (kVK_F11, "F11"), (kVK_F12, "F12")
        ]
        return entries.map { (UInt32($0.0), $0.1) }
    }()

    public var label: String {
        let flags: [(Int, String)] = [(controlKey, "⌃"), (optionKey, "⌥"), (shiftKey, "⇧"), (cmdKey, "⌘")]
        return flags.filter { modifiers & UInt32($0.0) != 0 }.map(\.1).joined()
            + " " + (Self.keys.first { $0.code == keyCode }?.label ?? "?")
    }
}

public struct ShortcutConfiguration: Codable, Equatable {
    public var bindings: [UInt32: Shortcut]

    public init(bindings: [UInt32: Shortcut]) { self.bindings = bindings }

    public static var defaults: Self {
        let keys: [(Direction, Int)] = [(.left, kVK_LeftArrow), (.right, kVK_RightArrow), (.up, kVK_UpArrow), (.down, kVK_DownArrow)]
        return Self(bindings: Dictionary(uniqueKeysWithValues: keys.map {
            ($0.0.rawValue, Shortcut(keyCode: UInt32($0.1), modifiers: UInt32(optionKey | cmdKey)))
        }))
    }

    public var validationError: String? {
        guard bindings.count == Direction.allCases.count,
              Direction.allCases.allSatisfy({ bindings[$0.rawValue] != nil }) else {
            return "네 방향의 단축키를 모두 지정해 주세요."
        }
        let allowed = UInt32(cmdKey | optionKey | controlKey | shiftKey)
        for shortcut in bindings.values {
            guard Shortcut.keys.contains(where: { $0.code == shortcut.keyCode }),
                  shortcut.modifiers & ~allowed == 0,
                  shortcut.modifiers & UInt32(cmdKey | optionKey | controlKey) != 0 else {
                return "단축키마다 ⌘, ⌥, ⌃ 중 하나 이상과 키를 선택해 주세요."
            }
        }
        guard Set(bindings.values).count == bindings.count else {
            return "같은 단축키를 여러 방향에 지정할 수 없습니다."
        }
        return nil
    }

    public static func load(from defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: "shortcuts.v1"),
              let decoded = try? JSONDecoder().decode(Self.self, from: data),
              decoded.validationError == nil else { return .defaults }
        return decoded
    }

    public func save(to defaults: UserDefaults = .standard) {
        guard validationError == nil, let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: "shortcuts.v1")
    }
}

public extension Direction {
    var title: String {
        switch self {
        case .left: return "왼쪽"
        case .right: return "오른쪽"
        case .up: return "위쪽"
        case .down: return "아래쪽"
        }
    }
}

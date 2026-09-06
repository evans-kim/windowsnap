import Carbon
import SnapCore

final class HotKeys {
    var onPress: ((Direction) -> Void)?
    private var handler: EventHandlerRef?
    private var references: [EventHotKeyRef] = []
    private var held: Set<UInt32> = []

    func start(configuration: ShortcutConfiguration) -> Bool {
        guard configuration.validationError == nil else { return false }
        stop()
        var types = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.signature == 0x57534E50 else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<HotKeys>.fromOpaque(context).takeUnretainedValue()
            if GetEventKind(event) == UInt32(kEventHotKeyReleased) {
                owner.held.remove(identifier.id)
            } else if owner.held.insert(identifier.id).inserted, let direction = Direction(rawValue: identifier.id) {
                owner.onPress?(direction)
            }
            return noErr
        }, types.count, &types, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard status == noErr else { return false }
        for direction in Direction.allCases {
            guard let shortcut = configuration.bindings[direction.rawValue] else { stop(); return false }
            var reference: EventHotKeyRef?
            let result = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, EventHotKeyID(signature: 0x57534E50, id: direction.rawValue), GetApplicationEventTarget(), 0, &reference)
            guard result == noErr, let reference else {
                stop()
                return false
            }
            references.append(reference)
        }
        return true
    }

    func stop() {
        references.forEach { UnregisterEventHotKey($0) }
        references.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
        held.removeAll()
    }

    deinit { stop() }
}

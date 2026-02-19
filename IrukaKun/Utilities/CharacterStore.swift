import Foundation

final class CharacterStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let key = "iruka_selected_character"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ type: CharacterType) {
        defaults.set(type.id, forKey: Self.key)
    }

    func load() -> CharacterType {
        guard let raw = defaults.string(forKey: Self.key),
              let type = CharacterType(id: raw) else {
            return .iruka
        }
        return type
    }
}

import Foundation

enum CharacterType: Sendable, Equatable, Hashable {
    case iruka
    case rakko
    case ono
    case syacho
    case custom(String)

    var id: String {
        switch self {
        case .iruka: return "iruka"
        case .rakko: return "rakko"
        case .ono: return "ono"
        case .syacho: return "syacho"
        case .custom(let id): return "custom:\(id)"
        }
    }

    init?(id: String) {
        switch id {
        case "iruka": self = .iruka
        case "rakko": self = .rakko
        case "ono": self = .ono
        case "syacho": self = .syacho
        default:
            if id.hasPrefix("custom:") {
                self = .custom(String(id.dropFirst(7)))
            } else {
                return nil
            }
        }
    }

    static var builtInCases: [CharacterType] { [.iruka, .rakko, .ono, .syacho] }

    var isBuiltIn: Bool {
        switch self {
        case .iruka, .rakko, .ono, .syacho: return true
        case .custom: return false
        }
    }

    func spritePrefix(for state: CharacterState) -> String {
        switch self {
        case .iruka, .rakko, .ono, .syacho:
            let base: String
            switch self {
            case .iruka: base = "iruka"
            case .rakko: base = "rakko"
            case .ono: base = "ono"
            case .syacho: base = "syacho"
            default: base = ""
            }
            switch state {
            case .idle:      return "\(base)_idle"
            case .happy:     return "\(base)_happy"
            case .sleeping:  return "\(base)_sleeping"
            case .surprised: return "\(base)_surprised"
            case .bored:     return "\(base)_bored"
            }
        case .custom:
            return ""
        }
    }

    var fallbackSpriteName: String {
        switch self {
        case .iruka: return "iruka_idle_0"
        case .rakko: return "rakko_idle_0"
        case .ono: return "ono_idle_0"
        case .syacho: return "syacho_idle_0"
        case .custom: return ""
        }
    }

    var menuBarIconName: String {
        switch self {
        case .iruka: return "fish.fill"
        case .rakko: return "pawprint.fill"
        case .ono: return "person.fill"
        case .syacho: return "person.crop.circle.fill"
        case .custom: return "photo.fill"
        }
    }

    var displayName: String {
        switch self {
        case .iruka: return "イルカ"
        case .rakko: return "ラッコ"
        case .ono: return "●no"
        case .syacho: return "syach●"
        case .custom(let id): return id
        }
    }
}

import Foundation

enum TimeOfDay: String, Sendable, Equatable {
    case morning    // 6:00 - 9:59
    case afternoon  // 10:00 - 17:59
    case evening    // 18:00 - 23:59
    case night      // 0:00 - 5:59

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<10: return .morning
        case 10..<18: return .afternoon
        case 18..<24: return .evening
        default: return .night
        }
    }

    static func current() -> TimeOfDay {
        from(hour: Calendar.current.component(.hour, from: Date()))
    }
}

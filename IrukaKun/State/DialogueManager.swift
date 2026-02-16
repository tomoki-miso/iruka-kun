import Foundation

struct DialogueData: Codable {
    let morning: [String]
    let afternoon: [String]
    let evening: [String]
    let night: [String]
    let clicked: [String]
    let dragged: [String]
    let bored: [String]
}

final class DialogueManager: Sendable {
    private let data: DialogueData

    init() {
        guard let url = Bundle.main.url(forResource: "Dialogues", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(DialogueData.self, from: jsonData)
        else {
            data = DialogueData(morning: [], afternoon: [], evening: [], night: [],
                                clicked: [], dragged: [], bored: [])
            return
        }
        data = decoded
    }

    func dialogues(for timeOfDay: TimeOfDay) -> [String] {
        switch timeOfDay {
        case .morning: return data.morning
        case .afternoon: return data.afternoon
        case .evening: return data.evening
        case .night: return data.night
        }
    }

    func dialogueForEvent(_ event: CharacterEvent) -> String? {
        let pool: [String]
        switch event {
        case .clicked: pool = data.clicked
        case .dragStarted: pool = data.dragged
        case .idleTimeout: pool = data.bored
        default: return nil
        }
        return pool.randomElement()
    }

    func timeBasedDialogue(hour: Int) -> String? {
        let timeOfDay = TimeOfDay.from(hour: hour)
        return dialogues(for: timeOfDay).randomElement()
    }
}

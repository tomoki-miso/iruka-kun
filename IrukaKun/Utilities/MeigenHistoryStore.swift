import Foundation

struct MeigenEntry: Codable {
    let meigen: String
    let auther: String
    let date: Date
}

final class MeigenHistoryStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let historyKey = "iruka_meigen_history"
    private static let maxEntries = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func add(meigen: String, auther: String) {
        var history = loadHistory()

        // Duplicate check
        if history.contains(where: { $0.meigen == meigen && $0.auther == auther }) {
            return
        }

        let entry = MeigenEntry(meigen: meigen, auther: auther, date: Date())
        history.insert(entry, at: 0)

        // Keep max entries
        if history.count > Self.maxEntries {
            history = Array(history.prefix(Self.maxEntries))
        }

        saveHistory(history)
    }

    func allHistory() -> [MeigenEntry] {
        loadHistory()
    }

    private func loadHistory() -> [MeigenEntry] {
        guard let data = defaults.data(forKey: Self.historyKey) else { return [] }
        return (try? JSONDecoder().decode([MeigenEntry].self, from: data)) ?? []
    }

    private func saveHistory(_ history: [MeigenEntry]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: Self.historyKey)
    }
}

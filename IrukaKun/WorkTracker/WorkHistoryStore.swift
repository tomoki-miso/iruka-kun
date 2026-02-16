import Foundation

final class WorkHistoryStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let storageKey = "iruka_work_history"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    func addDuration(_ duration: TimeInterval, for date: Date) {
        var history = loadHistory()
        let key = dateFormatter.string(from: date)
        history[key, default: 0] += duration
        defaults.set(history, forKey: Self.storageKey)
    }

    func totalDuration(for date: Date) -> TimeInterval {
        let key = dateFormatter.string(from: date)
        return loadHistory()[key] ?? 0
    }

    func todayTotal() -> TimeInterval {
        totalDuration(for: Date())
    }

    func recentHistory(days: Int = 7) -> [(date: String, duration: TimeInterval)] {
        let history = loadHistory()
        let calendar = Calendar.current
        let today = Date()

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let key = dateFormatter.string(from: date)
            guard let duration = history[key] else { return nil }
            return (date: key, duration: duration)
        }
    }

    private func loadHistory() -> [String: TimeInterval] {
        defaults.dictionary(forKey: Self.storageKey) as? [String: TimeInterval] ?? [:]
    }
}

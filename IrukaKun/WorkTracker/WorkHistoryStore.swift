import Foundation

final class WorkHistoryStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let historyKey = "iruka_work_history_v2"
    private static let presetsKey = "iruka_presets"
    private static let noPresetKey = "__none__"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    // MARK: - Duration

    func addDuration(_ duration: TimeInterval, for date: Date, preset: String? = nil) {
        var history = loadHistory()
        let dateKey = dateFormatter.string(from: date)
        let presetKey = preset ?? Self.noPresetKey
        var dayData = history[dateKey] ?? [:]
        dayData[presetKey, default: 0] += duration
        history[dateKey] = dayData
        defaults.set(history, forKey: Self.historyKey)
    }

    func totalDuration(for date: Date, preset: String? = nil) -> TimeInterval {
        let dateKey = dateFormatter.string(from: date)
        let presetKey = preset ?? Self.noPresetKey
        return loadHistory()[dateKey]?[presetKey] ?? 0
    }

    func todayTotal() -> TimeInterval {
        let dateKey = dateFormatter.string(from: Date())
        guard let dayData = loadHistory()[dateKey] else { return 0 }
        return dayData.values.reduce(0, +)
    }

    func todayBreakdown() -> [String: TimeInterval] {
        let dateKey = dateFormatter.string(from: Date())
        return loadHistory()[dateKey] ?? [:]
    }

    // MARK: - Presets

    var presets: [String] {
        defaults.stringArray(forKey: Self.presetsKey) ?? []
    }

    func addPreset(_ name: String) {
        var list = presets
        guard !list.contains(name) else { return }
        list.append(name)
        defaults.set(list, forKey: Self.presetsKey)
    }

    func removePreset(_ name: String) {
        var list = presets
        list.removeAll { $0 == name }
        defaults.set(list, forKey: Self.presetsKey)
    }

    // MARK: - Private

    private func loadHistory() -> [String: [String: TimeInterval]] {
        guard let raw = defaults.dictionary(forKey: Self.historyKey) else { return [:] }
        var result: [String: [String: TimeInterval]] = [:]
        for (dateKey, value) in raw {
            if let dayDict = value as? [String: TimeInterval] {
                result[dateKey] = dayDict
            }
        }
        return result
    }
}

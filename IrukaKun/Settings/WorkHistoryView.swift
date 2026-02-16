import SwiftUI

struct WorkHistoryView: View {
    let historyStore: WorkHistoryStore
    private let noPresetKey = "__none__"

    var body: some View {
        let history = historyStore.recentHistory(days: 7)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if history.isEmpty {
                    Text("まだ記録がありません")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    ForEach(history, id: \.dateString) { day in
                        daySection(day)
                    }
                }
            }
            .padding(20)
        }
        .frame(minWidth: 350, minHeight: 300)
    }

    private func daySection(_ day: WorkHistoryStore.DayHistory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatDateLabel(day.date))
                    .font(.headline)
                Spacer()
                Text("合計 \(formatTime(day.total))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            let sortedPresets = day.presets.sorted { $0.key < $1.key }
            ForEach(sortedPresets, id: \.key) { preset, duration in
                HStack {
                    Text(preset == noPresetKey ? "未分類" : preset)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formatTime(duration))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 12)
            }

            Divider()
        }
    }

    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
}

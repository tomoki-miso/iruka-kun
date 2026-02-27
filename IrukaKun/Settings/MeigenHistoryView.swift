import SwiftUI

struct MeigenHistoryView: View {
    let historyStore: MeigenHistoryStore
    @State private var copiedId: String?

    var body: some View {
        let history = historyStore.allHistory()

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if history.isEmpty {
                    Text("まだ名言がありません")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    ForEach(Array(history.enumerated()), id: \.offset) { index, entry in
                        meigenRow(entry, index: index)
                    }
                }
            }
            .padding(20)
        }
        .frame(minWidth: 400, minHeight: 350)
    }

    private func meigenRow(_ entry: MeigenEntry, index: Int) -> some View {
        let id = "\(index)-\(entry.meigen)"
        let isCopied = copiedId == id

        return Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("\(entry.meigen) — \(entry.auther)", forType: .string)
            copiedId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedId == id { copiedId = nil }
            }
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.meigen)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text("— \(entry.auther)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isCopied {
                        Text("コピーしました")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(formatDate(entry.date))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
}

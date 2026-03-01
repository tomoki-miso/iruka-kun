import SwiftUI

@MainActor
struct ReportView: View {
    @State private var selectedTab: ReportTab = .daily
    @State private var selectedDate: Date = Date()
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var generator: ReportGenerator?
    
    let historyStore: WorkHistoryStore

    enum ReportTab {
        case daily, weekly, monthly, range
    }

    var body: some View {
        VStack(spacing: 16) {
            // Tab selector
            Picker("Report Type", selection: $selectedTab) {
                Text("日次").tag(ReportTab.daily)
                Text("週次").tag(ReportTab.weekly)
                Text("月次").tag(ReportTab.monthly)
                Text("範囲").tag(ReportTab.range)
            }
            .pickerStyle(.segmented)
            .padding()

            // Date selection
            VStack(spacing: 12) {
                switch selectedTab {
                case .daily:
                    DatePicker(
                        "日付を選択",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                case .weekly, .monthly:
                    DatePicker(
                        "月を選択",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                case .range:
                    VStack {
                        DatePicker(
                            "開始日",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        DatePicker(
                            "終了日",
                            selection: $endDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .padding()

            // Report content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .daily:
                        dailyReportView()
                    case .weekly:
                        weeklyReportView()
                    case .monthly:
                        monthlyReportView()
                    case .range:
                        rangeReportView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Spacer()
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            generator = ReportGenerator(historyStore: historyStore)
        }
    }

    @ViewBuilder
    private func dailyReportView() -> some View {
        if let generator = generator {
            let report = generator.generateDailyReport(for: selectedDate)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(report.dateString)
                    .font(.headline)
                
                Divider()
                
                if report.breakdown.isEmpty {
                    Text("データなし")
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.breakdown.sorted(by: { $0.key < $1.key }), id: \.key) { preset, duration in
                            HStack {
                                let displayName = preset == "__none__" ? "未分類" : preset
                                Text(displayName)
                                Spacer()
                                Text(formatDuration(duration))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("合計")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatDuration(report.total))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
    }

    @ViewBuilder
    private func weeklyReportView() -> some View {
        if let generator = generator {
            let report = generator.generateWeeklyReport(for: selectedDate)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(report.weekString)
                    .font(.headline)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(report.days, id: \.date) { day in
                        HStack {
                            Text(day.dateString)
                            Spacer()
                            Text(formatDuration(day.total))
                                .monospacedDigit()
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("週計")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatDuration(report.total))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
    }

    @ViewBuilder
    private func monthlyReportView() -> some View {
        if let generator = generator {
            let report = generator.generateMonthlyReport(for: selectedDate)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(report.monthString)
                    .font(.headline)
                
                Divider()
                
                if report.days.isEmpty {
                    Text("データなし")
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.days, id: \.date) { day in
                            HStack {
                                Text(day.dateString)
                                Spacer()
                                Text(formatDuration(day.total))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("月計")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatDuration(report.total))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
    }

    @ViewBuilder
    private func rangeReportView() -> some View {
        if let generator = generator {
            let report = generator.generateRangeReport(from: startDate, to: endDate)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(report.rangeString)
                    .font(.headline)
                
                Divider()
                
                if report.days.isEmpty {
                    Text("データなし")
                        .foregroundColor(.gray)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.days, id: \.date) { day in
                            HStack {
                                Text(day.dateString)
                                Spacer()
                                Text(formatDuration(day.total))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("範囲合計")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatDuration(report.total))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    ReportView(historyStore: WorkHistoryStore(defaults: UserDefaults(suiteName: "preview")!))
}

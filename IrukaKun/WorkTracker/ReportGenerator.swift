import AppKit

@MainActor
final class ReportGenerator {
    struct DailyReport: Sendable {
        let date: Date
        let dateString: String
        let breakdown: [String: TimeInterval]

        var total: TimeInterval {
            breakdown.values.reduce(0, +)
        }
    }

    struct WeeklyReport: Sendable {
        struct DayData: Sendable {
            let date: Date
            let dateString: String
            let total: TimeInterval
        }

        let startDate: Date
        let endDate: Date
        let weekString: String
        let days: [DayData]

        var total: TimeInterval {
            days.reduce(0) { $0 + $1.total }
        }
    }

    struct MonthlyReport: Sendable {
        struct DayData: Sendable {
            let date: Date
            let dateString: String
            let total: TimeInterval
        }

        let month: Date
        let monthString: String
        let days: [DayData]

        var total: TimeInterval {
            days.reduce(0) { $0 + $1.total }
        }
    }

    struct RangeReport: Sendable {
        struct DayData: Sendable {
            let date: Date
            let dateString: String
            let total: TimeInterval
        }

        let startDate: Date
        let endDate: Date
        let rangeString: String
        let days: [DayData]

        var total: TimeInterval {
            days.reduce(0) { $0 + $1.total }
        }
    }

    private let historyStore: WorkHistoryStore

    init(historyStore: WorkHistoryStore) {
        self.historyStore = historyStore
    }

    func generateDailyReport(for date: Date) -> DailyReport {
        let breakdown = historyStore.todayBreakdown(for: date)
        let dateString = formatDate(date)
        return DailyReport(date: date, dateString: dateString, breakdown: breakdown)
    }

    func generateWeeklyReport(for date: Date) -> WeeklyReport {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        var days: [WeeklyReport.DayData] = []
        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let breakdown = historyStore.todayBreakdown(for: dayDate)
                let total = breakdown.values.reduce(0, +)
                let dateString = formatDate(dayDate)
                days.append(WeeklyReport.DayData(date: dayDate, dateString: dateString, total: total))
            }
        }

        let weekString = "Week of \(formatDate(startOfWeek)) - \(formatDate(endOfWeek))"
        return WeeklyReport(startDate: startOfWeek, endDate: endOfWeek, weekString: weekString, days: days)
    }

    func generateMonthlyReport(for date: Date) -> MonthlyReport {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth = calendar.date(from: components)!
        let monthString = formatMonth(date)

        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return MonthlyReport(month: startOfMonth, monthString: monthString, days: [])
        }

        var days: [MonthlyReport.DayData] = []
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                let breakdown = historyStore.todayBreakdown(for: dayDate)
                let total = breakdown.values.reduce(0, +)
                let dateString = formatDate(dayDate)
                days.append(MonthlyReport.DayData(date: dayDate, dateString: dateString, total: total))
            }
        }

        return MonthlyReport(month: startOfMonth, monthString: monthString, days: days)
    }

    func generateRangeReport(from startDate: Date, to endDate: Date) -> RangeReport {
        let calendar = Calendar.current
        let rangeString = "\(formatDate(startDate)) - \(formatDate(endDate))"

        var days: [RangeReport.DayData] = []
        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate <= endDay {
            let breakdown = historyStore.todayBreakdown(for: currentDate)
            let total = breakdown.values.reduce(0, +)
            let dateString = formatDate(currentDate)
            days.append(RangeReport.DayData(date: currentDate, dateString: dateString, total: total))

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return RangeReport(startDate: startDate, endDate: endDate, rangeString: rangeString, days: days)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

import XCTest
@testable import IrukaKun

@MainActor
final class ReportGeneratorTests: XCTestCase {
    var generator: ReportGenerator!
    var historyStore: WorkHistoryStore!

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        historyStore = WorkHistoryStore(defaults: defaults)
        generator = ReportGenerator(historyStore: historyStore)
    }

    override func tearDown() async throws {
        generator = nil
        historyStore = nil
    }

    // MARK: - Daily Report

    func testGenerateDailyReportEmpty() {
        let report = generator.generateDailyReport(for: Date())
        XCTAssertEqual(report.total, 0)
        XCTAssertTrue(report.breakdown.isEmpty)
    }

    func testGenerateDailyReportWithData() {
        let today = Date()
        historyStore.addDuration(3600, for: today, preset: "ProjectA")
        historyStore.addDuration(1800, for: today, preset: "ProjectB")

        let report = generator.generateDailyReport(for: today)
        XCTAssertEqual(report.total, 5400)
        XCTAssertEqual(report.breakdown["ProjectA"], 3600)
        XCTAssertEqual(report.breakdown["ProjectB"], 1800)
    }

    func testGenerateDailyReportDateFormatted() {
        let report = generator.generateDailyReport(for: Date())
        XCTAssertFalse(report.dateString.isEmpty)
    }

    // MARK: - Weekly Report

    func testGenerateWeeklyReportStructure() {
        let report = generator.generateWeeklyReport(for: Date())
        XCTAssertEqual(report.days.count, 7)
    }

    func testGenerateWeeklyReportWithData() {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                historyStore.addDuration(TimeInterval(i + 1) * 1800, for: date)
            }
        }

        let report = generator.generateWeeklyReport(for: today)
        XCTAssertGreaterThan(report.total, 0)
    }

    // MARK: - Monthly Report

    func testGenerateMonthlyReportStructure() {
        let report = generator.generateMonthlyReport(for: Date())
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: Date()) else { return }
        XCTAssertEqual(report.days.count, range.count)
    }

    func testGenerateMonthlyReportWithData() {
        let today = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: today)
        let startOfMonth = calendar.date(from: components)!

        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                historyStore.addDuration(3600, for: date)
            }
        }

        let report = generator.generateMonthlyReport(for: today)
        XCTAssertGreaterThan(report.total, 0)
    }

    // MARK: - Range Report

    func testGenerateRangeReportSingleDay() {
        let today = Date()
        historyStore.addDuration(3600, for: today)

        let report = generator.generateRangeReport(from: today, to: today)
        XCTAssertEqual(report.days.count, 1)
        XCTAssertEqual(report.total, 3600)
    }

    func testGenerateRangeReportMultipleDays() {
        let calendar = Calendar.current
        let today = Date()
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: today) else { return }

        var currentDate = today
        while currentDate <= endDate {
            historyStore.addDuration(1800, for: currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        let report = generator.generateRangeReport(from: today, to: endDate)
        XCTAssertEqual(report.days.count, 7)
        XCTAssertEqual(report.total, 12600)
    }

    func testGenerateRangeReportPreservesDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: 2, to: today) else { return }

        let report = generator.generateRangeReport(from: today, to: endDate)
        XCTAssertEqual(report.startDate, today)
        XCTAssertEqual(report.endDate, calendar.startOfDay(for: endDate))
    }

    // MARK: - Data Consistency

    func testReportDataConsistency() {
        let today = Date()
        historyStore.addDuration(3600, for: today, preset: "ProjectA")
        historyStore.addDuration(1800, for: today, preset: "ProjectB")

        let dailyReport = generator.generateDailyReport(for: today)
        let total = historyStore.todayTotal()

        XCTAssertEqual(dailyReport.total, total)
    }

    func testReportBreakdownMatches() {
        let today = Date()
        let breakdown = ["ProjectA": 3600.0, "ProjectB": 1800.0]

        for (preset, duration) in breakdown {
            historyStore.addDuration(duration, for: today, preset: preset)
        }

        let report = generator.generateDailyReport(for: today)
        for (preset, duration) in breakdown {
            XCTAssertEqual(report.breakdown[preset], duration)
        }
    }
}

import XCTest
@testable import IrukaKun

final class WorkHistoryStoreTests: XCTestCase {
    var store: WorkHistoryStore!
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        store = WorkHistoryStore(defaults: defaults)
    }

    func testAddAndRetrieveDuration() {
        let today = Date()
        store.addDuration(3600, for: today, preset: "ProjectA")
        XCTAssertEqual(store.totalDuration(for: today, preset: "ProjectA"), 3600, accuracy: 0.1)
    }

    func testAddDurationAccumulates() {
        let today = Date()
        store.addDuration(1800, for: today, preset: "ProjectA")
        store.addDuration(1200, for: today, preset: "ProjectA")
        XCTAssertEqual(store.totalDuration(for: today, preset: "ProjectA"), 3000, accuracy: 0.1)
    }

    func testTodayTotalAcrossPresets() {
        store.addDuration(3600, for: Date(), preset: "A")
        store.addDuration(1800, for: Date(), preset: "B")
        XCTAssertEqual(store.todayTotal(), 5400, accuracy: 0.1)
    }

    func testTodayTotalReturnsZeroWhenNoData() {
        XCTAssertEqual(store.todayTotal(), 0, accuracy: 0.1)
    }

    func testDifferentPresetsAreSeparate() {
        let today = Date()
        store.addDuration(100, for: today, preset: "A")
        store.addDuration(200, for: today, preset: "B")
        XCTAssertEqual(store.totalDuration(for: today, preset: "A"), 100, accuracy: 0.1)
        XCTAssertEqual(store.totalDuration(for: today, preset: "B"), 200, accuracy: 0.1)
    }

    func testTodayBreakdown() {
        store.addDuration(3600, for: Date(), preset: "A")
        store.addDuration(1800, for: Date(), preset: "B")
        let breakdown = store.todayBreakdown()
        XCTAssertEqual(breakdown["A"] ?? 0, 3600, accuracy: 0.1)
        XCTAssertEqual(breakdown["B"] ?? 0, 1800, accuracy: 0.1)
    }

    func testNilPresetUsesDefaultKey() {
        let today = Date()
        store.addDuration(500, for: today, preset: nil)
        XCTAssertEqual(store.totalDuration(for: today, preset: nil), 500, accuracy: 0.1)
        XCTAssertEqual(store.todayTotal(), 500, accuracy: 0.1)
    }

    func testPresetsCRUD() {
        XCTAssertEqual(store.presets, [])
        store.addPreset("ProjectA")
        store.addPreset("ProjectB")
        XCTAssertEqual(store.presets, ["ProjectA", "ProjectB"])
        store.removePreset("ProjectA")
        XCTAssertEqual(store.presets, ["ProjectB"])
    }

    func testAddDuplicatePresetIsIgnored() {
        store.addPreset("A")
        store.addPreset("A")
        XCTAssertEqual(store.presets, ["A"])
    }

    func testRecentHistoryReturnsData() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        store.addDuration(3600, for: today, preset: "A")
        store.addDuration(1800, for: today, preset: "B")
        store.addDuration(7200, for: yesterday, preset: "A")
        let history = store.recentHistory(days: 7)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].presets["A"] ?? 0, 3600, accuracy: 0.1)
        XCTAssertEqual(history[0].presets["B"] ?? 0, 1800, accuracy: 0.1)
        XCTAssertEqual(history[0].total, 5400, accuracy: 0.1)
        XCTAssertEqual(history[1].presets["A"] ?? 0, 7200, accuracy: 0.1)
        XCTAssertEqual(history[1].total, 7200, accuracy: 0.1)
    }

    func testRecentHistorySkipsEmptyDays() {
        store.addDuration(100, for: Date(), preset: nil)
        let history = store.recentHistory(days: 7)
        XCTAssertEqual(history.count, 1)
    }
}

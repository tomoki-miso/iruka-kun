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
        store.addDuration(3600, for: today)
        XCTAssertEqual(store.totalDuration(for: today), 3600, accuracy: 0.1)
    }

    func testAddDurationAccumulates() {
        let today = Date()
        store.addDuration(1800, for: today)
        store.addDuration(1200, for: today)
        XCTAssertEqual(store.totalDuration(for: today), 3000, accuracy: 0.1)
    }

    func testTodayTotal() {
        store.addDuration(7200, for: Date())
        XCTAssertEqual(store.todayTotal(), 7200, accuracy: 0.1)
    }

    func testTodayTotalReturnsZeroWhenNoData() {
        XCTAssertEqual(store.todayTotal(), 0, accuracy: 0.1)
    }

    func testRecentHistory() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        store.addDuration(3600, for: today)
        store.addDuration(7200, for: yesterday)

        let history = store.recentHistory(days: 7)
        XCTAssertEqual(history.count, 2)
    }

    func testDifferentDaysAreSeparate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        store.addDuration(100, for: today)
        store.addDuration(200, for: yesterday)

        XCTAssertEqual(store.totalDuration(for: today), 100, accuracy: 0.1)
        XCTAssertEqual(store.totalDuration(for: yesterday), 200, accuracy: 0.1)
    }
}

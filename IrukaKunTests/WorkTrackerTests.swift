import XCTest
@testable import IrukaKun

@MainActor
final class WorkTrackerTests: XCTestCase {
    var tracker: WorkTracker!
    var historyStore: WorkHistoryStore!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        historyStore = WorkHistoryStore(defaults: defaults)
        tracker = WorkTracker(historyStore: historyStore, idleThreshold: 2.0)
    }

    override func tearDown() {
        tracker.stop()
        super.tearDown()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(tracker.state, .idle)
    }

    func testStartTransitionsToTracking() {
        tracker.start()
        XCTAssertEqual(tracker.state, .tracking)
    }

    func testStopTransitionsToIdle() {
        tracker.start()
        tracker.stop()
        XCTAssertEqual(tracker.state, .idle)
    }

    func testStopFromIdleDoesNothing() {
        tracker.stop()
        XCTAssertEqual(tracker.state, .idle)
    }

    func testStartWhileTrackingDoesNothing() {
        tracker.start()
        tracker.start()
        XCTAssertEqual(tracker.state, .tracking)
    }

    func testElapsedTimeIncrements() {
        tracker.start()
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertGreaterThanOrEqual(tracker.elapsedTime, 1.0)
    }

    func testStopSavesToHistory() {
        tracker.start()
        // Wait a moment so elapsed > 0
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
        tracker.stop()
        XCTAssertGreaterThan(historyStore.todayTotal(), 0)
    }

    func testOnStateChangedCallback() {
        var states: [WorkTracker.State] = []
        tracker.onStateChanged = { state in
            states.append(state)
        }
        tracker.start()
        tracker.stop()
        XCTAssertEqual(states, [.tracking, .idle])
    }

    func testElapsedTimeResetsOnStop() {
        tracker.start()
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
        tracker.stop()
        XCTAssertEqual(tracker.elapsedTime, 0)
    }

    func testCurrentPresetDefault() {
        XCTAssertNil(tracker.currentPreset)
    }

    func testSetCurrentPreset() {
        tracker.currentPreset = "ProjectA"
        XCTAssertEqual(tracker.currentPreset, "ProjectA")
    }

    func testStopSavesToPreset() {
        tracker.currentPreset = "ProjectA"
        tracker.start()
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 { expectation.fulfill() }
        }
        wait(for: [expectation], timeout: 3.0)
        tracker.stop()
        XCTAssertGreaterThan(historyStore.totalDuration(for: Date(), preset: "ProjectA"), 0)
    }

    func testSwitchPresetSavesCurrentAndResets() {
        tracker.currentPreset = "A"
        tracker.start()
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 { expectation.fulfill() }
        }
        wait(for: [expectation], timeout: 3.0)
        tracker.switchPreset(to: "B")
        XCTAssertEqual(tracker.currentPreset, "B")
        XCTAssertEqual(tracker.elapsedTime, 0)
        XCTAssertEqual(tracker.state, .tracking)
        XCTAssertGreaterThan(historyStore.totalDuration(for: Date(), preset: "A"), 0)
    }

    func testSwitchPresetWhileIdleJustSetsPreset() {
        tracker.switchPreset(to: "B")
        XCTAssertEqual(tracker.currentPreset, "B")
        XCTAssertEqual(tracker.state, .idle)
    }
}

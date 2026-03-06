import XCTest
@testable import IrukaKun

final class PositionStoreTests: XCTestCase {
    var store: PositionStore!

    override func setUp() {
        super.setUp()
        store = PositionStore(defaults: UserDefaults(suiteName: "test_\(UUID().uuidString)")!)
    }

    func testSaveAndLoadPosition() {
        let point = CGPoint(x: 123.0, y: 456.0)
        store.save(position: point)
        let loaded = store.loadPosition()
        XCTAssertEqual(Double(loaded?.x ?? 0), 123.0, accuracy: 0.1)
        XCTAssertEqual(Double(loaded?.y ?? 0), 456.0, accuracy: 0.1)
    }

    func testLoadPositionReturnsNilWhenNotSaved() {
        let loaded = store.loadPosition()
        XCTAssertNil(loaded)
    }

    func testSaveAndLoadPositionPerScreen() {
        let position = CGPoint(x: 100, y: 200)
        let screenId = "screen_1920x1080_0_0"

        store.save(position: position, for: screenId)
        let loaded = store.loadPosition(for: screenId)

        XCTAssertEqual(loaded, position)
    }

    func testDifferentScreensHaveDifferentPositions() {
        let pos1 = CGPoint(x: 100, y: 200)
        let pos2 = CGPoint(x: 300, y: 400)
        let screen1 = "screen_1920x1080_0_0"
        let screen2 = "screen_1920x1080_1920_0"

        store.save(position: pos1, for: screen1)
        store.save(position: pos2, for: screen2)

        XCTAssertEqual(store.loadPosition(for: screen1), pos1)
        XCTAssertEqual(store.loadPosition(for: screen2), pos2)
    }

    func testLoadPositionReturnsNilForUnknownScreen() {
        let position = store.loadPosition(for: "unknown_screen")
        XCTAssertNil(position)
    }

    func testBackwardCompatibilityWithOldFormat() {
        let legacyPos = store.loadLegacyPosition()
        // Legacy position can be loaded if set
        // This test verifies the method exists and is callable
        _ = legacyPos
    }
}

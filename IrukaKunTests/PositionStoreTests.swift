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
}

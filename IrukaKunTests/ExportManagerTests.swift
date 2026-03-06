import XCTest
@testable import IrukaKun

@MainActor
final class ExportManagerTests: XCTestCase {
    func testExportToJSON() {
        let data: [ExportManager.WorkData] = [
            ("2026-03-06", "Coding", 3600),
            ("2026-03-06", "Meeting", 1800)
        ]
        
        let json = ExportManager.toJSON(data)
        XCTAssertFalse(json.isEmpty)
        XCTAssert(json.contains("Coding"))
        XCTAssert(json.contains("3600"))
    }

    func testExportToCSV() {
        let data: [ExportManager.WorkData] = [
            ("2026-03-06", "Coding", 3600),
            ("2026-03-06", "Meeting", 1800)
        ]
        
        let csv = ExportManager.toCSV(data)
        XCTAssertFalse(csv.isEmpty)
        XCTAssert(csv.contains("Date"))
        XCTAssert(csv.contains("Coding"))
        XCTAssert(csv.contains("1.00"))
    }

    func testEmptyDataHandling() {
        let json = ExportManager.toJSON([])
        let csv = ExportManager.toCSV([])
        
        XCTAssertFalse(json.isEmpty)
        XCTAssertFalse(csv.isEmpty)
        XCTAssert(json.contains("["))
        XCTAssert(csv.contains("Date"))
    }

    func testCSVFormatting() {
        let data: [ExportManager.WorkData] = [
            ("2026-03-06", "Test Category", 7200)
        ]
        
        let csv = ExportManager.toCSV(data)
        XCTAssert(csv.contains("Test Category"))
        XCTAssert(csv.contains("7200"))
        XCTAssert(csv.contains("2.00"))
    }
}

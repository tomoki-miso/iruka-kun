import XCTest
@testable import IrukaKun

@MainActor
final class CalendarManagerTests: XCTestCase {
    func testGenerateICalendarContent() {
        let events: [CalendarManager.CalendarEvent] = [
            ("2026-03-06", "Work Session", 3600),
            ("2026-03-07", "Meeting", 1800)
        ]
        
        let iCalContent = CalendarManager.toICalendar(events)
        XCTAssertFalse(iCalContent.isEmpty)
        XCTAssert(iCalContent.contains("BEGIN:VCALENDAR"))
        XCTAssert(iCalContent.contains("END:VCALENDAR"))
        XCTAssert(iCalContent.contains("Work Session"))
    }

    func testCalendarEventFormatting() {
        let icalEvent = CalendarManager.formatEvent(
            date: "2026-03-06",
            title: "Work",
            duration: 3600
        )
        
        XCTAssert(icalEvent.contains("BEGIN:VEVENT"))
        XCTAssert(icalEvent.contains("END:VEVENT"))
        XCTAssert(icalEvent.contains("SUMMARY:Work"))
        XCTAssert(icalEvent.contains("PT60M"))
    }

    func testEmptyCalendarHandling() {
        let iCalContent = CalendarManager.toICalendar([])
        XCTAssertFalse(iCalContent.isEmpty)
        XCTAssert(iCalContent.contains("BEGIN:VCALENDAR"))
        XCTAssert(iCalContent.contains("END:VCALENDAR"))
    }

    func testDateFormatConversion() {
        let icalEvent = CalendarManager.formatEvent(
            date: "2026-03-06",
            title: "Test",
            duration: 1800
        )
        
        XCTAssert(icalEvent.contains("20260306"))
    }
}

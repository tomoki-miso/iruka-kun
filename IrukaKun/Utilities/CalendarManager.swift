import Foundation

@MainActor
final class CalendarManager {
    typealias CalendarEvent = (date: String, title: String, duration: Int)

    static func toICalendar(_ events: [CalendarEvent]) -> String {
        var ical = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//iruka-kun//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:iruka-kun Work Calendar
        X-WR-TIMEZONE:Asia/Tokyo

        """
        
        for event in events {
            ical += formatEvent(date: event.date, title: event.title, duration: event.duration)
        }
        
        ical += "END:VCALENDAR\n"
        return ical
    }

    static func formatEvent(date: String, title: String, duration: Int) -> String {
        let uid = "\(date)-\(title.replacingOccurrences(of: " ", with: "-"))@iruka-kun"
        let durationMinutes = duration / 60
        
        return """
        BEGIN:VEVENT
        UID:\(uid)
        DTSTAMP:\(getCurrentTimestamp())
        DTSTART:\(dateToICalFormat(date))
        DURATION:PT\(durationMinutes)M
        SUMMARY:\(escapeICalText(title))
        DESCRIPTION:Work session tracked by iruka-kun
        CATEGORIES:Work
        END:VEVENT

        """
    }

    private static func dateToICalFormat(_ dateStr: String) -> String {
        dateStr.replacingOccurrences(of: "-", with: "")
    }

    private static func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: Date())
    }

    private static func escapeICalText(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: ",", with: "\\,")
        return escaped
    }
}

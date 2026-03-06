import Foundation

@MainActor
final class ExportManager {
    typealias WorkData = (date: String, category: String, duration: Int)

    static func toJSON(_ data: [WorkData]) -> String {
        let jsonData = data.map { item -> [String: Any] in
            [
                "date": item.date,
                "category": item.category,
                "duration": item.duration,
                "durationHours": Double(item.duration) / 3600.0
            ]
        }
        
        guard let jsonObject = try? JSONSerialization.data(
            withJSONObject: jsonData,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return "[]"
        }
        
        return String(data: jsonObject, encoding: .utf8) ?? "[]"
    }

    static func toCSV(_ data: [WorkData]) -> String {
        var csv = "Date,Category,Duration (seconds),Duration (hours)\n"
        
        for item in data {
            let hours = Double(item.duration) / 3600.0
            csv += "\(item.date),\(item.category),\(item.duration),\(String(format: "%.2f", hours))\n"
        }
        
        return csv
    }

    static func saveToFile(
        _ content: String,
        filename: String,
        in directory: FileManager.SearchPathDirectory = .documentDirectory
    ) -> URL? {
        guard let docURL = FileManager.default.urls(
            for: directory,
            in: .userDomainMask
        ).first else { return nil }
        
        let fileURL = docURL.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            NSLog("Failed to save file: \(error)")
            return nil
        }
    }
}

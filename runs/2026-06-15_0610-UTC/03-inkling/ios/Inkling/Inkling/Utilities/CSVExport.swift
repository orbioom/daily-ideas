import Foundation

/// Builds a CSV of every log entry. A Pro feature — the free tier keeps unlimited history, Pro
/// lets you take it with you. Fields are quoted/escaped so notes with commas survive.
enum CSVExport {

    /// Produce CSV text from trackers and their entries.
    static func make(trackers: [Tracker]) -> String {
        var rows = ["date,tracker,kind,value,unit,note"]
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"

        let sortedTrackers = trackers.sorted { $0.sortOrder < $1.sortOrder }
        for tracker in sortedTrackers {
            for entry in tracker.sortedEntries {
                let date = iso.string(from: entry.date)
                let value = formatValue(entry.value)
                let unit = tracker.unit ?? ""
                let note = entry.note ?? ""
                let cols = [date, tracker.name, tracker.kind.title, value, unit, note].map(escape)
                rows.append(cols.joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n")
    }

    /// Write the CSV to a temp file and return its URL, or nil on failure (never throws to UI).
    static func writeTempFile(trackers: [Tracker]) -> URL? {
        let text = make(trackers: trackers)
        let name = "Inkling-export-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func formatValue(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.2f", v)
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

import Foundation

/// Builds a CSV of session history (Pro feature). Pure string building — no I/O.
enum CSVExport {
    static func sessionsCSV(_ sessions: [Session]) -> String {
        let header = "Date,Format,Game,Stakes,Location,Duration (min),Buy-in,Cash-out,Profit,Entries,Place,Tag,Notes"
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let rows = sessions
            .sorted { $0.date < $1.date }
            .map { s -> String in
                let fields: [String] = [
                    df.string(from: s.date),
                    s.format.rawValue,
                    s.gameType.rawValue,
                    s.stakes,
                    s.location,
                    String(max(0, s.durationMinutes)),
                    Money.plain(s.buyIn, fractionDigits: 2),
                    Money.plain(s.cashOut, fractionDigits: 2),
                    Money.plain(s.profit, fractionDigits: 2),
                    s.tournamentEntries.map(String.init) ?? "",
                    s.tournamentPlace.map(String.init) ?? "",
                    s.tag,
                    s.notes
                ]
                return fields.map(escape).joined(separator: ",")
            }

        return ([header] + rows).joined(separator: "\n")
    }

    /// Escapes a CSV field: wraps in quotes and doubles inner quotes when needed.
    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Writes the CSV to a temporary file and returns its URL for sharing.
    /// Returns nil if the write fails (caller shows a calm error state).
    static func writeTempFile(_ csv: String, filename: String = "felt-sessions.csv") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

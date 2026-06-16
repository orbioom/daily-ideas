import Foundation

/// Builds CSV exports of the library and diary. A simple, dependency-free serializer.
enum CSVExport {

    /// Library rows: one per title.
    static func library(titles: [Title]) -> String {
        var rows: [String] = []
        rows.append("Name,Year,Kind,Status,Rating,Genres,Runtime,Creator,WatchedEpisodes,TotalEpisodes")
        let sorted = titles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        for t in sorted {
            let cols = [
                t.name,
                String(t.year),
                t.kind.displayName,
                t.status.displayName,
                t.rating.map { String(format: "%.1f", $0) } ?? "",
                t.genresRaw.joined(separator: "; "),
                String(t.runtimeMinutes),
                t.creator,
                String(t.watchedEpisodes),
                String(t.totalEpisodes)
            ]
            rows.append(cols.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// Diary rows: one per logged watch, newest first.
    static func diary(titles: [Title]) -> String {
        var rows: [String] = []
        rows.append("Date,Title,Year,Rating,Rewatch,Review")
        var entries: [(DiaryEntry, Title)] = []
        for t in titles {
            for e in t.entries { entries.append((e, t)) }
        }
        entries.sort { $0.0.watchedDate > $1.0.watchedDate }
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]
        for (e, t) in entries {
            let cols = [
                df.string(from: e.watchedDate),
                t.name,
                String(t.year),
                e.rating > 0 ? String(format: "%.1f", e.rating) : "",
                e.isRewatch ? "Yes" : "No",
                e.review
            ]
            rows.append(cols.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    /// RFC-4180-style escaping: wrap in quotes if it contains comma, quote, or newline.
    private static func escape(_ field: String) -> String {
        let needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n")
        if needsQuotes {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

import Foundation

/// Builds CSV / plain-text exports of the collection and play history.
enum Exporter {

    private static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// CSV of every owned/known game in the collection.
    static func collectionCSV(_ games: [BoardGame]) -> String {
        var lines: [String] = []
        lines.append("Title,Designer,MinPlayers,MaxPlayers,PlayTimeMin,Weight,Year,Status,Rating,PlayCount")
        for g in games.sorted(by: { $0.title < $1.title }) {
            let row = [
                g.title,
                g.designer,
                String(g.minPlayers),
                String(g.maxPlayers),
                String(g.playTimeMin),
                String(format: "%.1f", g.weight),
                String(g.yearPublished),
                g.status.label,
                String(g.rating),
                String(g.playCount)
            ].map(csvEscape).joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// CSV of every logged play, one row per play.
    static func playsCSV(_ games: [BoardGame]) -> String {
        var lines: [String] = []
        lines.append("Date,Game,DurationMin,Location,Players,Winners,Scores")
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        var rows: [(Date, String)] = []
        for g in games {
            for p in g.plays {
                let players = p.results.map { $0.playerName }.joined(separator: " | ")
                let winners = p.winnerNames.joined(separator: " | ")
                let scores = p.results
                    .map { "\($0.playerName)=\($0.score.map(String.init) ?? "—")" }
                    .joined(separator: " | ")
                let row = [
                    fmt.string(from: p.date),
                    g.title,
                    String(p.durationMin),
                    p.location,
                    players,
                    winners,
                    scores
                ].map(csvEscape).joined(separator: ",")
                rows.append((p.date, row))
            }
        }
        for r in rows.sorted(by: { $0.0 > $1.0 }) {
            lines.append(r.1)
        }
        return lines.joined(separator: "\n")
    }

    /// Human-readable text summary suitable for sharing.
    static func summaryText(_ games: [BoardGame]) -> String {
        let owned = games.filter { $0.status == .owned }.count
        let totalPlays = games.reduce(0) { $0 + $1.playCount }
        var out = "Meeple Collection Export\n"
        out += "Generated \(Date().formatted(date: .abbreviated, time: .shortened))\n\n"
        out += "Games tracked: \(games.count) (\(owned) owned)\n"
        out += "Total plays logged: \(totalPlays)\n\n"
        out += collectionCSV(games)
        return out
    }
}

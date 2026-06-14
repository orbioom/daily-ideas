import Foundation

/// Builds a clean plain-text export of practice history and per-note mastery.
enum ExportBuilder {
    static func build(sessions: [DrillSession], stats: [NoteStat]) -> String {
        var lines: [String] = []
        lines.append("CLEF — PRACTICE EXPORT")
        lines.append(Date().formatted(date: .abbreviated, time: .shortened))
        lines.append("")

        let valid = sessions.filter { $0.total > 0 }.sorted { $0.date > $1.date }
        let totalNotes = valid.reduce(0) { $0 + $1.total }
        let totalCorrect = valid.reduce(0) { $0 + $1.correct }
        let overall = totalNotes > 0 ? Double(totalCorrect) / Double(totalNotes) : 0

        lines.append("SUMMARY")
        lines.append("Drills completed: \(valid.count)")
        lines.append("Notes read: \(totalNotes)")
        lines.append("Overall accuracy: \(Int(overall * 100))%")
        lines.append("")

        lines.append("SESSIONS")
        if valid.isEmpty {
            lines.append("(none yet)")
        } else {
            for s in valid {
                let date = s.date.formatted(date: .abbreviated, time: .shortened)
                let avg = s.avgMs > 0 ? String(format: "%.1fs avg", s.avgMs / 1000) : "—"
                lines.append("\(date) · \(s.clef.displayName) · \(s.mode.label) · \(s.correct)/\(s.total) (\(Int(s.accuracy * 100))%) · \(avg) · streak \(s.bestStreak)")
            }
        }
        lines.append("")

        lines.append("NOTE MASTERY")
        let sorted = stats.sorted { $0.key < $1.key }
        if sorted.isEmpty {
            lines.append("(none yet)")
        } else {
            for stat in sorted {
                let midi = NoteStat.midi(fromKey: stat.key) ?? 0
                let name = Pitch(midi).name(useFlats: false)
                lines.append("\(stat.key) (\(name)): \(Int(stat.mastery * 100))% over \(stat.seen) tries")
            }
        }

        return lines.joined(separator: "\n")
    }
}

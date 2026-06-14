import Foundation

/// A computed snapshot powering the Progress screen.
struct ProgressSnapshot {
    struct SessionPoint: Identifiable {
        let id: UUID
        let index: Int
        let date: Date
        let accuracy: Double
        let avgMs: Double
        let total: Int
    }
    struct MasteryCell: Identifiable {
        let id: String
        let midi: Int
        let letter: String
        let mastery: Double
        let seen: Int
    }

    var totalSessions: Int
    var totalNotes: Int
    var overallAccuracy: Double
    var bestStreak: Int
    var sessionPoints: [SessionPoint]       // oldest → newest, for line charts
    var masteryByClef: [Clef: [MasteryCell]]

    static let empty = ProgressSnapshot(totalSessions: 0, totalNotes: 0, overallAccuracy: 0,
                                        bestStreak: 0, sessionPoints: [], masteryByClef: [:])
}

enum ProgressStats {
    static func compute(sessions: [DrillSession], stats: [NoteStat]) -> ProgressSnapshot {
        let valid = sessions.filter { $0.total > 0 }
        let ordered = valid.sorted { $0.date < $1.date }

        var points: [ProgressSnapshot.SessionPoint] = []
        for (i, s) in ordered.enumerated() {
            points.append(.init(id: s.id, index: i + 1, date: s.date,
                                accuracy: s.accuracy, avgMs: s.avgMs, total: s.total))
        }

        let totalNotes = valid.reduce(0) { $0 + $1.total }
        let totalCorrect = valid.reduce(0) { $0 + $1.correct }
        let overall = totalNotes > 0 ? Double(totalCorrect) / Double(totalNotes) : 0
        let bestStreak = valid.map(\.bestStreak).max() ?? 0

        var byClef: [Clef: [ProgressSnapshot.MasteryCell]] = [:]
        for stat in stats {
            guard let midi = NoteStat.midi(fromKey: stat.key),
                  let clefRaw = stat.key.split(separator: ":").first,
                  let clef = Clef(rawValue: String(clefRaw)) else { continue }
            let cell = ProgressSnapshot.MasteryCell(id: stat.key,
                                                    midi: midi,
                                                    letter: Pitch(midi).letterName,
                                                    mastery: stat.mastery,
                                                    seen: stat.seen)
            byClef[clef, default: []].append(cell)
        }
        for (clef, cells) in byClef {
            byClef[clef] = cells.sorted { $0.midi < $1.midi }
        }

        return ProgressSnapshot(totalSessions: valid.count,
                                totalNotes: totalNotes,
                                overallAccuracy: overall,
                                bestStreak: bestStreak,
                                sessionPoints: points,
                                masteryByClef: byClef)
    }
}

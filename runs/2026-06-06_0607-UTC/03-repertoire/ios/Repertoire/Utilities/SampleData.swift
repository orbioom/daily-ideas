import Foundation
import SwiftData

/// Real, on-brand seed content so a first launch is a living app — pieces with spots
/// and several weeks of sessions so streaks, heatmaps, and time-by-piece are alive.
/// Inserted once (gated by SettingsStore.hasSeeded) and reused by "Reset to sample".
enum SampleData {

    static func insert(into context: ModelContext) {
        let pieces = insertPieces(into: context)
        insertSessions(into: context, pieces: pieces)
    }

    /// Remove every piece and session (cascade removes spots and entries).
    static func clear(_ context: ModelContext) throws {
        for piece in try context.fetch(FetchDescriptor<Piece>()) { context.delete(piece) }
        for session in try context.fetch(FetchDescriptor<PracticeSession>()) { context.delete(session) }
    }

    // MARK: - Pieces

    private static func makePiece(_ title: String,
                                  composer: String,
                                  instrument: String,
                                  difficulty: Difficulty,
                                  status: PieceStatus,
                                  target: Int,
                                  key: String,
                                  notes: String,
                                  daysOld: Int,
                                  spots: [(String, Int, Int, Int, String)],
                                  into context: ModelContext) -> Piece {
        let created = Calendar.current.date(byAdding: .day, value: -daysOld, to: .now) ?? .now
        let piece = Piece(title: title, composer: composer, instrument: instrument,
                          difficulty: difficulty, status: status, targetTempo: target,
                          key: key, notes: notes, createdAt: created)
        context.insert(piece)
        for (idx, spot) in spots.enumerated() {
            let s = PracticeSpot(name: spot.0, order: idx,
                                 currentTempo: spot.1, targetTempo: spot.2,
                                 mastery: spot.3, notes: spot.4,
                                 createdAt: Calendar.current.date(byAdding: .second,
                                                                  value: idx, to: created) ?? created)
            s.piece = piece
            piece.spots.append(s)
            context.insert(s)
        }
        return piece
    }

    private static func insertPieces(into context: ModelContext) -> [Piece] {
        var pieces: [Piece] = []

        pieces.append(makePiece(
            "Prelude in C", composer: "J.S. Bach", instrument: "Piano",
            difficulty: .easy, status: .polishing, target: 76, key: "C major",
            notes: "Even, flowing broken chords. Keep the pedal honest.",
            daysOld: 40,
            spots: [
                ("Opening figure (bars 1–4)", 72, 76, 5, "Voicing the top line."),
                ("Bars 19–24 chromatic descent", 60, 76, 3, "Right-hand evenness."),
                ("Final cadence", 70, 76, 4, "Ritardando shape.")
            ],
            into: context))

        pieces.append(makePiece(
            "Clair de Lune", composer: "Claude Debussy", instrument: "Piano",
            difficulty: .advanced, status: .learning, target: 66, key: "D♭ major",
            notes: "Pacing and pedal colour over speed. Voicing inner lines.",
            daysOld: 30,
            spots: [
                ("Opening (bars 1–14)", 54, 66, 3, "Rubato breath at phrase ends."),
                ("Arpeggio section (bars 27–37)", 40, 60, 2, "LH leaps; slow and clean first."),
                ("Climax (bars 47–50)", 48, 60, 2, "Balance the melody over the swell."),
                ("Coda", 58, 66, 3, "Let it dissolve.")
            ],
            into: context))

        pieces.append(makePiece(
            "Gymnopédie No. 1", composer: "Erik Satie", instrument: "Piano",
            difficulty: .beginner, status: .maintenance, target: 60, key: "D major",
            notes: "Calm and unhurried. A good warm-up piece.",
            daysOld: 60,
            spots: [
                ("Main theme", 58, 60, 5, "Stays steady."),
                ("Middle section", 56, 60, 4, "Watch the harmony shifts.")
            ],
            into: context))

        pieces.append(makePiece(
            "Asturias (Leyenda)", composer: "Isaac Albéniz", instrument: "Guitar",
            difficulty: .virtuoso, status: .learning, target: 132, key: "E minor",
            notes: "Right-hand stamina. Build the tremolo-like ostinato slowly.",
            daysOld: 18,
            spots: [
                ("Ostinato (opening)", 96, 132, 2, "Alternation evenness; metronome ladder."),
                ("Melody over pedal", 84, 120, 2, "Keep the bass present."),
                ("Middle lyrical section", 80, 108, 1, "Tone and rubato.")
            ],
            into: context))

        pieces.append(makePiece(
            "Autumn Leaves", composer: "Joseph Kosma", instrument: "Jazz Guitar",
            difficulty: .intermediate, status: .polishing, target: 120, key: "G minor",
            notes: "Comping then single-line. Target a relaxed medium swing.",
            daysOld: 22,
            spots: [
                ("Head (comping)", 110, 120, 4, "Chord voicings, shell + extensions."),
                ("Solo chorus changes", 96, 120, 3, "Guide tones through ii–V–I."),
                ("Trading fours", 100, 120, 2, "Time feel under pressure.")
            ],
            into: context))

        pieces.append(makePiece(
            "Minuet in G", composer: "Christian Petzold", instrument: "Piano",
            difficulty: .beginner, status: .retired, target: 100, key: "G major",
            notes: "Learned and shelved. Kept for the record.",
            daysOld: 120,
            spots: [
                ("Whole piece", 100, 100, 5, "Performance-ready, then retired.")
            ],
            into: context))

        return pieces
    }

    // MARK: - Sessions

    /// A practice plan: for each "days ago", a list of (pieceIndex, minutes) and a tempo/quality.
    private static func insertSessions(into context: ModelContext, pieces: [Piece]) {
        guard !pieces.isEmpty else { return }

        // Index-safe accessor.
        func piece(_ i: Int) -> Piece? { pieces.indices.contains(i) ? pieces[i] : nil }

        // (daysAgo, [(pieceIndex, minutes)], tempo, quality)
        let plan: [(Int, [(Int, Int)], Int, SessionQuality)] = [
            (29, [(2, 20)], 58, .good),
            (28, [(0, 25), (2, 10)], 72, .steady),
            (26, [(1, 30)], 50, .shaky),
            (25, [(0, 20), (1, 20)], 66, .steady),
            (23, [(2, 15)], 60, .flowing),
            (22, [(4, 30)], 100, .steady),
            (21, [(1, 35)], 52, .good),
            (20, [(0, 25)], 74, .good),
            (18, [(3, 30)], 96, .rough),
            (17, [(4, 25), (2, 10)], 110, .steady),
            (16, [(1, 30)], 54, .steady),
            (14, [(3, 35)], 100, .shaky),
            (13, [(0, 20), (4, 20)], 76, .good),
            (12, [(1, 30)], 58, .good),
            (10, [(3, 30), (2, 10)], 104, .steady),
            (9,  [(4, 35)], 116, .good),
            (8,  [(1, 40)], 60, .flowing),
            (7,  [(0, 25)], 76, .flowing),
            (6,  [(3, 35)], 108, .steady),
            (5,  [(1, 30), (2, 10)], 62, .good),
            (4,  [(4, 30)], 118, .good),
            (3,  [(3, 40)], 112, .steady),
            (2,  [(1, 35)], 64, .flowing),
            (1,  [(0, 20), (2, 10)], 76, .good)
        ]

        let cal = Calendar.current
        for (daysAgo, items, tempo, quality) in plan {
            let baseDate = cal.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            // Anchor at a believable practice hour (18:30) for tidy day bucketing.
            let date = cal.date(bySettingHour: 18, minute: 30, second: 0, of: baseDate) ?? baseDate

            let resolved = items.compactMap { (idx, mins) -> (Piece, Int)? in
                guard let p = piece(idx) else { return nil }
                return (p, mins)
            }
            guard !resolved.isEmpty else { continue }

            let totalSeconds = resolved.reduce(0) { $0 + $1.1 * 60 }
            let session = PracticeSession(date: date, durationSeconds: totalSeconds,
                                          focusNotes: focusNote(for: quality),
                                          quality: quality, tempo: Tempo.clamp(tempo))
            context.insert(session)
            for (p, mins) in resolved {
                let entry = SessionEntry(durationSeconds: mins * 60)
                entry.session = session
                entry.piece = p
                session.entries.append(entry)
                context.insert(entry)
            }
        }
    }

    private static func focusNote(for quality: SessionQuality) -> String {
        switch quality {
        case .rough:   return "Hands separate, slow. Frustrating but useful."
        case .shaky:   return "Worked the tricky bars at half tempo."
        case .steady:  return "Solid run-throughs; nudged the metronome up."
        case .good:    return "Felt secure; focused on phrasing."
        case .flowing: return "Came together — played it through musically."
        }
    }
}

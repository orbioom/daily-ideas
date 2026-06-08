import Foundation
import SwiftData

/// A breathing technique defined by four phase lengths (seconds) and a number
/// of rounds. A phase of 0 is skipped.
@Model
final class BreathPattern {
    var id: UUID
    var name: String
    var detail: String
    var inhale: Double
    var holdIn: Double
    var exhale: Double
    var holdOut: Double
    var rounds: Int
    var isCustom: Bool
    var order: Int

    init(id: UUID = UUID(),
         name: String,
         detail: String,
         inhale: Double,
         holdIn: Double,
         exhale: Double,
         holdOut: Double,
         rounds: Int,
         isCustom: Bool = false,
         order: Int = 0) {
        self.id = id
        self.name = name
        self.detail = detail
        self.inhale = inhale
        self.holdIn = holdIn
        self.exhale = exhale
        self.holdOut = holdOut
        self.rounds = rounds
        self.isCustom = isCustom
        self.order = order
    }

    /// One full round duration in seconds.
    var roundSeconds: Double { inhale + holdIn + exhale + holdOut }
    /// Total planned session length in seconds.
    var totalSeconds: Double { roundSeconds * Double(rounds) }

    var ratioLabel: String {
        let parts = [inhale, holdIn, exhale, holdOut].map { v -> String in
            v == v.rounded() ? String(Int(v)) : String(format: "%.0f", v)
        }
        return parts.joined(separator: "-")
    }

    static func ensureDefaults(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<BreathPattern>())) ?? 0
        guard existing == 0 else { return }
        // name, detail, in, holdIn, ex, holdOut, rounds
        let seeds: [(String, String, Double, Double, Double, Double, Int)] = [
            ("Box breathing", "Calm and focus — equal four counts.", 4, 4, 4, 4, 8),
            ("4-7-8 relax", "Dr Weil's unwind for sleep.", 4, 7, 8, 0, 6),
            ("Coherent", "Five-and-five resonance breathing.", 5, 0, 5, 0, 12),
            ("Calm down", "Long exhale to settle the nervous system.", 4, 0, 6, 0, 10),
            ("Energize", "Quick, light breaths to wake up.", 2, 0, 2, 0, 20),
            ("Deep reset", "Slow six-count waves.", 6, 2, 6, 2, 8),
        ]
        for (i, s) in seeds.enumerated() {
            context.insert(BreathPattern(name: s.0, detail: s.1, inhale: s.2, holdIn: s.3,
                                         exhale: s.4, holdOut: s.5, rounds: s.6, order: i))
        }
        try? context.save()
    }
}

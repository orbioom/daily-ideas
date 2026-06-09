import Foundation
import SwiftData

/// Seeds ~28 sample readings spanning the last ~10 weeks so the Journal and
/// Insights screens are populated on first launch. Guarded to run at most once.
/// The 78-card deck itself is static (TarotDeck), so Library is always full.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Reading>())) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        var rng = SystemRandomNumberGenerator()

        let spreads = SpreadCatalog.all
        let questions = [
            "What should I focus on this week?",
            "How can I move forward in my career?",
            "What does this relationship need?",
            "Where is my energy best spent?",
            "What am I not seeing clearly?",
            "How do I find more balance?",
            "",
            "What is ready to be released?",
            "",
            "What lesson is this moment teaching me?"
        ]
        let notes = [
            "This landed surprisingly true. Sat with it over morning coffee.",
            "Felt the pull toward the Action card all day.",
            "A gentle reminder to slow down and trust the process.",
            "",
            "Came back to this after a hard conversation — it helped.",
            "",
            "The reversed card stung a little, but it was honest.",
            ""
        ]

        for i in 0..<28 {
            // Spread starts across the last ~70 days.
            let daysAgo = Int.random(in: 0...70, using: &rng)
            guard let dayBase = cal.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let hour = Int.random(in: 7...22, using: &rng)
            let minute = [0, 10, 20, 30, 45].randomElement(using: &rng) ?? 0
            guard let date = cal.date(bySettingHour: hour, minute: minute, second: 0, of: dayBase) else { continue }

            // Favor shorter spreads so the journal feels realistic.
            let spread: Spread = {
                let roll = Int.random(in: 0...100, using: &rng)
                if roll < 35 { return spreads[0] }              // Single Card
                if roll < 65 { return spreads[1] }              // Past/Present/Future
                if roll < 85 { return spreads[2] }              // Situation/Action/Outcome
                if roll < 95 { return spreads[3] }              // Relationship
                return spreads[4]                               // Celtic Cross
            }()

            let allowReversed = Int.random(in: 0...100, using: &rng) < 70
            let draw = ArcanaEngine.draw(spread: spread, allowReversed: allowReversed)

            let reading = Reading(
                date: date,
                spreadName: spread.name,
                question: questions.randomElement(using: &rng) ?? "",
                note: notes.randomElement(using: &rng) ?? "",
                isFavorite: Int.random(in: 0...100, using: &rng) < 25
            )
            context.insert(reading)

            for (idx, drawn) in draw.enumerated() {
                let position = idx < spread.positions.count ? spread.positions[idx] : spread.positions.last
                let drawnCard = DrawnCard(
                    positionIndex: idx,
                    positionTitle: position?.title ?? "Card \(idx + 1)",
                    cardID: drawn.cardID,
                    isReversed: drawn.reversed,
                    note: (i % 7 == 0 && idx == 0) ? "This one stood out." : ""
                )
                drawnCard.reading = reading
                context.insert(drawnCard)
            }
        }

        try? context.save()
    }

    /// Removes every saved reading (and its cards via cascade). Used by the
    /// destructive Settings action.
    static func clearAllReadings(_ context: ModelContext) {
        let readings = (try? context.fetch(FetchDescriptor<Reading>())) ?? []
        for r in readings { context.delete(r) }
        try? context.save()
    }
}

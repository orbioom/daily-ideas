import Foundation
import SwiftData

enum SeedData {
    private static let captions = [
        "Long walk by the river before work.",
        "Coffee with an old friend — laughed until it hurt.",
        "Rough day, but I showed up.",
        "First tomatoes from the balcony garden.",
        "Finished the book I'd been putting off.",
        "Rain all day. Cozy and quiet.",
        "Tried a new recipe; it actually worked.",
        "Tough conversation, but I'm glad we had it.",
        "Sunset turned the whole sky pink tonight.",
        "Slept in, no alarm, no plans. Bliss.",
        "Hit a small milestone at work.",
        "Kids drew on the windows again. Couldn't be mad.",
        "Went for a run and felt like myself again.",
        "Quiet evening, candles, early to bed.",
        "Saw live music for the first time in ages.",
        "Cleaned the whole apartment — feels lighter.",
        "Got caught in a downpour and just laughed.",
        "Made it to the gym three days in a row.",
        "Phone call from home, right when I needed it.",
        "Tired, but it was a good kind of tired."
    ]

    /// Populate a few months of varied entries so the year grid feels alive.
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var rng = SystemRandomNumberGenerator()
        let moodWeights = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5]   // skew positive

        for offset in 0...118 {
            // ~62% of days have an entry, leaving natural gaps.
            if Int.random(in: 0..<100, using: &rng) < 38 { continue }
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let mood = moodWeights.randomElement(using: &rng) ?? 3
            let caption = Bool.random(using: &rng) ? (captions.randomElement(using: &rng) ?? "") : ""
            let entry = DayEntry(day: day, caption: caption, moodIndex: mood)
            entry.createdAt = day
            entry.updatedAt = day
            context.insert(entry)
        }
        try? context.save()
    }
}

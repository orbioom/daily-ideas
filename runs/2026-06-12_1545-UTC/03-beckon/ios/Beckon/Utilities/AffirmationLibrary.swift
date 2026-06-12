import Foundation

/// A small curated library of present-tense affirmations to inspire new
/// intentions and power the daily affirmation card. Deterministic by date.
enum AffirmationLibrary {
    static let all: [(category: IntentionCategory, text: String)] = [
        (.wealth, "Money flows to me easily and abundantly."),
        (.wealth, "I am worthy of financial freedom and security."),
        (.wealth, "Opportunities to prosper find me every day."),
        (.love, "I am surrounded by love and give it freely."),
        (.love, "I attract a relationship that honors who I am."),
        (.love, "I am open to receiving deep, genuine connection."),
        (.health, "My body is strong, healthy, and full of energy."),
        (.health, "Every day I grow more vibrant and well."),
        (.career, "I am stepping into the career I am meant for."),
        (.career, "My work is recognized, valued, and rewarded."),
        (.career, "I lead with confidence and clarity."),
        (.growth, "I am becoming the person I am proud to be."),
        (.growth, "I trust the timing of my life."),
        (.growth, "I release what no longer serves me."),
        (.peace, "I am calm, centered, and at peace."),
        (.peace, "I breathe in calm and breathe out tension."),
        (.peace, "I am exactly where I need to be."),
    ]

    static func dailyText(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let key = UInt64((comps.year ?? 2026) * 10000 + (comps.month ?? 1) * 100 + (comps.day ?? 1))
        var rng = SplitMix64(seed: key)
        let idx = Int(rng.next() % UInt64(all.count))
        return all[idx].text
    }

    static func suggestions(for category: IntentionCategory) -> [String] {
        all.filter { $0.category == category }.map(\.text)
    }
}

struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

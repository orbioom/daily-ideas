import Foundation

/// Deterministic daily guidance derived from a Personal Day number and date.
enum DailyGuidance {

    /// Several flavoured lines per number; the date picks one deterministically,
    /// so the same person gets the same guidance on the same day, but variety
    /// across days.
    private static let lines: [Int: [String]] = [
        1: [
            "A doorway day. Start the thing you keep postponing — momentum favours you now.",
            "Lead today. Your initiative carries unusual weight; make the first move.",
            "Plant a seed of your own choosing. Independence is your fuel today."
        ],
        2: [
            "Slow down and listen. Cooperation will get you further than force today.",
            "A day for partnership. Tend a relationship; small kindnesses compound.",
            "Patience over pushing. Let things settle and the right answer will surface."
        ],
        3: [
            "Create and connect. Speak, write, or make something — your voice lands well.",
            "Lightness is allowed. Let joy and play recharge you today.",
            "Share an idea you've been holding. The room is ready to hear it."
        ],
        4: [
            "Build the foundation. Unglamorous, steady work pays off disproportionately now.",
            "Bring order to one corner of your life. Structure frees you today.",
            "Keep a promise to yourself. Discipline now becomes ease later."
        ],
        5: [
            "Embrace the unexpected. Stay flexible and follow the interesting detour.",
            "A day to move. Change your scenery, your routine, or your mind.",
            "Say yes to one new experience. Variety is the medicine today."
        ],
        6: [
            "Tend to home and the people in it. Care given today returns multiplied.",
            "Make something more beautiful. Harmony is yours to create now.",
            "Take responsibility gently — and remember to include yourself in the care."
        ],
        7: [
            "Withdraw a little. Solitude and reflection will reveal what noise hides.",
            "Study, ponder, or rest. Today rewards depth over activity.",
            "Trust your intuition; it knows something your logic hasn't caught up to."
        ],
        8: [
            "Step into your authority. Make the decision and own the outcome.",
            "A day for ambition and money matters. Act with fair, clear judgment.",
            "Lead with competence. The material world is responsive to you now."
        ],
        9: [
            "Release what's finished. Letting go today clears space for what's next.",
            "Give generously and widely. Compassion is your strength now.",
            "Complete a cycle. Forgive, tidy, and close a loop with grace."
        ],
        11: [
            "Your intuition runs high — pay attention to the flashes and the dreams.",
            "Inspire someone today. You are a channel for something larger.",
            "Stay grounded amid the sensitivity; write down the insights as they come."
        ],
        22: [
            "Think big and build. A grand vision can take a concrete first step today.",
            "Marry the dream to a plan. You have rare power to manifest now.",
            "Lay one real brick of a large ambition. The legacy starts with today."
        ],
        33: [
            "Lead with love. Your care can heal more than you realise today.",
            "Teach, mentor, or uplift — but keep something in reserve for yourself.",
            "Selfless service is yours today; let it flow without draining the well."
        ]
    ]

    /// Pick a deterministic line for the personal-day number on a given date.
    static func line(forPersonalDay number: Int, on date: Date) -> String {
        let pool = lines[number] ?? lines[singleRoot(number)] ?? ["Move through today with intention and an open heart."]
        guard !pool.isEmpty else { return "Move through today with intention and an open heart." }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear + number) % pool.count
        return pool[index]
    }

    private static func singleRoot(_ n: Int) -> Int {
        var v = abs(n)
        while v > 9 { v = String(v).compactMap { $0.wholeNumberValue }.reduce(0, +) }
        return max(1, v)
    }
}

import Foundation

/// Rotating prompts that nudge the writer without being prescriptive.
/// A deterministic prompt-of-day is chosen by date so it feels intentional.
enum Prompts {
    static let gratitude = [
        "Who made your day a little easier?",
        "What small comfort did you enjoy today?",
        "What part of your body are you thankful for?",
        "What in your home are you grateful to have?",
        "What did you learn or notice today?",
        "Which person are you glad to know?",
        "What sound, smell, or taste pleased you?",
        "What went better than expected?",
        "What about this season do you appreciate?",
        "What is something free that brings you joy?"
    ]

    static let intention = [
        "How do you want to feel by tonight?",
        "What is one kind thing you can do today?",
        "What deserves your full attention today?",
        "What would make today feel like enough?",
        "What can you let go of today?",
        "Who could use a little of your patience today?",
        "What is the one thing that truly matters today?"
    ]

    static let win = [
        "What is one thing you handled well?",
        "Where did you show up for someone?",
        "What did you do, even though it was hard?",
        "What moment today would you relive?",
        "What progress did you make, however small?",
        "When did you feel most like yourself?"
    ]

    static func ofDay(_ list: [String], date: Date = .now, calendar: Calendar = .current) -> String {
        guard !list.isEmpty else { return "" }
        let key = PlentyEngine.dayKey(date, calendar: calendar)
        return list[abs(key) % list.count]
    }
}

import Foundation

struct JournalPrompt: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let category: PromptCategory
}

enum PromptCategory: String, CaseIterable, Identifiable {
    case reflection = "Reflection"
    case gratitude  = "Gratitude"
    case growth     = "Growth"
    case creativity = "Creativity"
    case relationships = "Relationships"
    case evening    = "Evening"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .reflection:    return "moon.stars.fill"
        case .gratitude:     return "heart.fill"
        case .growth:        return "leaf.fill"
        case .creativity:    return "paintbrush.pointed.fill"
        case .relationships: return "person.2.fill"
        case .evening:       return "bed.double.fill"
        }
    }
}

/// A hand-curated prompt deck. Deterministic "prompt of the day" so the same
/// prompt surfaces all day, then rotates.
enum PromptLibrary {

    static let all: [JournalPrompt] = [
        // Reflection
        .init(text: "What is one thing you learned about yourself today?", category: .reflection),
        .init(text: "Describe a moment today you'd like to remember.", category: .reflection),
        .init(text: "What occupied most of your thoughts today, and why?", category: .reflection),
        .init(text: "If today had a title, what would it be?", category: .reflection),
        .init(text: "What did you avoid today, and what was underneath that?", category: .reflection),
        // Gratitude
        .init(text: "Name three small things you're grateful for right now.", category: .gratitude),
        .init(text: "Who made your day a little better, and how?", category: .gratitude),
        .init(text: "What comfort do you have today that you often overlook?", category: .gratitude),
        .init(text: "What part of your body or health are you thankful for today?", category: .gratitude),
        // Growth
        .init(text: "What is one small step toward a goal you took today?", category: .growth),
        .init(text: "Where did you push past discomfort recently?", category: .growth),
        .init(text: "What would the version of you from a year ago admire about today?", category: .growth),
        .init(text: "What habit is quietly shaping who you're becoming?", category: .growth),
        // Creativity
        .init(text: "Describe the light in the room right now.", category: .creativity),
        .init(text: "Write about an ordinary object as if you'd never seen it before.", category: .creativity),
        .init(text: "What idea has been knocking on your door lately?", category: .creativity),
        .init(text: "If today were a color, which one and why?", category: .creativity),
        // Relationships
        .init(text: "Who would you like to reconnect with, and what would you say?", category: .relationships),
        .init(text: "What did someone teach you recently without meaning to?", category: .relationships),
        .init(text: "Describe a conversation that stayed with you.", category: .relationships),
        // Evening
        .init(text: "What can you let go of before sleep tonight?", category: .evening),
        .init(text: "How did your energy move through the day?", category: .evening),
        .init(text: "What are you looking forward to tomorrow?", category: .evening),
        .init(text: "What would make tonight feel like a gentle close?", category: .evening),
    ]

    static func category(_ c: PromptCategory) -> [JournalPrompt] {
        all.filter { $0.category == c }
    }

    /// Stable prompt for a given day — same all day, rotates each day.
    static func promptOfDay(for date: Date = .now, calendar: Calendar = .current) -> JournalPrompt {
        guard !all.isEmpty else {
            return JournalPrompt(text: "What's on your mind today?", category: .reflection)
        }
        let dayNumber = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return all[abs(dayNumber) % all.count]
    }
}

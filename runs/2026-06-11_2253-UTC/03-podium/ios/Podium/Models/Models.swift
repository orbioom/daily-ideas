import Foundation
import SwiftData

/// One recorded and analyzed practice talk.
@Model
final class SpeechSession {
    var date: Date
    var duration: TimeInterval
    var transcript: String
    var promptTitle: String
    var wordCount: Int
    var fillerCount: Int
    var wordsPerMinute: Double
    /// Unique words ÷ total words (0...1).
    var vocabularyDiversity: Double
    /// Composite 0–100 delivery score.
    var score: Int
    /// Filler word → occurrences, e.g. ["um": 4, "you know": 2].
    var fillerBreakdown: [String: Int]

    init(date: Date = Date(), duration: TimeInterval, transcript: String,
         promptTitle: String, wordCount: Int, fillerCount: Int,
         wordsPerMinute: Double, vocabularyDiversity: Double, score: Int,
         fillerBreakdown: [String: Int]) {
        self.date = date
        self.duration = duration
        self.transcript = transcript
        self.promptTitle = promptTitle
        self.wordCount = wordCount
        self.fillerCount = fillerCount
        self.wordsPerMinute = wordsPerMinute
        self.vocabularyDiversity = vocabularyDiversity
        self.score = score
        self.fillerBreakdown = fillerBreakdown
    }

    var fillersPerMinute: Double {
        duration > 0 ? Double(fillerCount) / (duration / 60) : 0
    }
}

/// A practice prompt. Static content, not persisted.
struct Prompt: Identifiable, Hashable {
    let id: String
    let category: PromptCategory
    let title: String
    let text: String
}

enum PromptCategory: String, CaseIterable, Identifiable {
    case interview = "Interview"
    case impromptu = "Impromptu"
    case presentation = "Presentation"
    case toast = "Toasts & intros"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .interview: return "person.crop.rectangle"
        case .impromptu: return "sparkles"
        case .presentation: return "rectangle.on.rectangle"
        case .toast: return "wineglass"
        }
    }
}

enum PromptLibrary {
    static let all: [Prompt] = [
        // Interview
        Prompt(id: "iv1", category: .interview, title: "Tell me about yourself",
               text: "Answer the classic opener in under 90 seconds: who you are, what you've done, why this role."),
        Prompt(id: "iv2", category: .interview, title: "A hard problem",
               text: "Describe the hardest technical or professional problem you've solved, and how."),
        Prompt(id: "iv3", category: .interview, title: "A time you failed",
               text: "Tell the story of a real failure, what you learned, and what changed afterwards."),
        Prompt(id: "iv4", category: .interview, title: "Why this company?",
               text: "Pitch why you want to work somewhere specific — without flattery or filler."),
        Prompt(id: "iv5", category: .interview, title: "Your proudest project",
               text: "Walk through your proudest piece of work: the goal, your role, the result."),
        Prompt(id: "iv6", category: .interview, title: "Conflict on a team",
               text: "Describe a disagreement with a colleague and how you resolved it."),
        // Impromptu
        Prompt(id: "im1", category: .impromptu, title: "Defend a hot take",
               text: "Pick an unpopular opinion you hold and argue for it convincingly for one minute."),
        Prompt(id: "im2", category: .impromptu, title: "Explain your job to a 10-year-old",
               text: "No jargon allowed. Make a kid understand and care about what you do."),
        Prompt(id: "im3", category: .impromptu, title: "The object next to you",
               text: "Pick any object in the room and sell it like it's the greatest invention ever."),
        Prompt(id: "im4", category: .impromptu, title: "Best advice you've received",
               text: "What's the best advice anyone ever gave you, and how did it play out?"),
        Prompt(id: "im5", category: .impromptu, title: "A place that changed you",
               text: "Describe somewhere you've been that shifted how you see things."),
        Prompt(id: "im6", category: .impromptu, title: "Teach something in 60 seconds",
               text: "Teach any skill you have — knot tying, naming clouds, parallel parking — in a minute."),
        // Presentation
        Prompt(id: "pr1", category: .presentation, title: "Your project kickoff",
               text: "Open a project kickoff: the problem, the plan, what you need from the room."),
        Prompt(id: "pr2", category: .presentation, title: "Quarterly update",
               text: "Deliver a crisp status update: wins, misses, and the one thing that matters next."),
        Prompt(id: "pr3", category: .presentation, title: "Pitch your idea",
               text: "You have two minutes with a decision-maker. Pitch the idea you care most about."),
        Prompt(id: "pr4", category: .presentation, title: "Explain a chart",
               text: "Imagine one chart that matters to your work. Walk an audience through what it shows and why it matters."),
        Prompt(id: "pr5", category: .presentation, title: "Handle the hard question",
               text: "A skeptical audience member just challenged your numbers. Respond with composure."),
        // Toasts
        Prompt(id: "to1", category: .toast, title: "Wedding toast",
               text: "Raise a glass to two people you love: one story, one laugh, one wish."),
        Prompt(id: "to2", category: .toast, title: "Introduce a speaker",
               text: "Introduce a keynote speaker: why they matter and why the room should listen."),
        Prompt(id: "to3", category: .toast, title: "Farewell to a colleague",
               text: "Send off a departing teammate: what they did, what you'll miss."),
        Prompt(id: "to4", category: .toast, title: "Birthday speech",
               text: "Thirty seconds for the birthday person: warm, specific, no rambling."),
    ]

    static func prompts(in category: PromptCategory) -> [Prompt] {
        all.filter { $0.category == category }
    }

    static let freeTalk = Prompt(id: "free", category: .impromptu, title: "Free talk",
                                 text: "Talk about anything. Podium listens for pace and filler words.")
}

/// A focused exercise with technique guidance.
struct Drill: Identifiable {
    let id: String
    let title: String
    let focus: String
    let instructions: String
    let promptID: String
    let suggestedSeconds: Int
}

enum DrillLibrary {
    static let all: [Drill] = [
        Drill(id: "d1", title: "The pause swap", focus: "Filler words",
              instructions: "Every time you feel an “um” coming, close your mouth and pause instead. A silent beat sounds confident; a filler sounds nervous. Aim for under 2 fillers per minute.",
              promptID: "im4", suggestedSeconds: 60),
        Drill(id: "d2", title: "Slow is smooth", focus: "Pacing",
              instructions: "Speak deliberately slower than feels natural — target 110–130 words per minute. Rushing is the #1 tell of nerves. Watch the live pace readout while you talk.",
              promptID: "iv1", suggestedSeconds: 90),
        Drill(id: "d3", title: "One idea per sentence", focus: "Clarity",
              instructions: "Short sentences. Full stops. No “and… and… so…” chains. End each sentence cleanly, breathe, start the next.",
              promptID: "pr2", suggestedSeconds: 90),
        Drill(id: "d4", title: "The cold open", focus: "Openings",
              instructions: "Start mid-story — no “so basically”, no throat-clearing. Your first sentence should be a hook. Record only the first 30 seconds, repeatedly.",
              promptID: "pr3", suggestedSeconds: 30),
        Drill(id: "d5", title: "Stretch your vocabulary", focus: "Word variety",
              instructions: "Tell the same story twice; the second time, ban every key word you used the first time. Pushes your vocabulary diversity score up.",
              promptID: "im5", suggestedSeconds: 120),
        Drill(id: "d6", title: "Land the ending", focus: "Closings",
              instructions: "Plan only your final sentence before you start. Everything you say must steer to it. No trailing off, no “…yeah, so that's it”.",
              promptID: "to3", suggestedSeconds: 60),
    ]

    static func prompt(for drill: Drill) -> Prompt {
        PromptLibrary.all.first { $0.id == drill.promptID } ?? PromptLibrary.freeTalk
    }
}

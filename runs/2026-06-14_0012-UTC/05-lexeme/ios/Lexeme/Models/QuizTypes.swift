import Foundation

/// The quiz formats Lexeme can present.
enum QuizMode: String, CaseIterable, Identifiable, Codable {
    case definitionToWord   // shows a definition, pick the word
    case wordToDefinition   // shows a word, pick the definition
    case synonymMatch       // shows a word, pick a synonym
    case fillBlank          // shows the example with the word blanked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .definitionToWord: return "Definition to Word"
        case .wordToDefinition: return "Word to Definition"
        case .synonymMatch:     return "Synonym Match"
        case .fillBlank:        return "Fill in the Blank"
        }
    }

    var shortTitle: String {
        switch self {
        case .definitionToWord: return "Def to Word"
        case .wordToDefinition: return "Word to Def"
        case .synonymMatch:     return "Synonyms"
        case .fillBlank:        return "Fill Blank"
        }
    }

    var systemImage: String {
        switch self {
        case .definitionToWord: return "text.magnifyingglass"
        case .wordToDefinition: return "character.book.closed"
        case .synonymMatch:     return "arrow.left.arrow.right"
        case .fillBlank:        return "rectangle.and.pencil.and.ellipsis"
        }
    }

    /// Free tier only gets the two multiple-choice basics; Pro unlocks all.
    var requiresPro: Bool {
        switch self {
        case .definitionToWord, .wordToDefinition: return false
        case .synonymMatch, .fillBlank:            return true
        }
    }
}

/// A single generated quiz question. Value type — built fresh each session.
struct QuizQuestion: Identifiable {
    let id = UUID()
    let mode: QuizMode
    /// The word this question is about (the correct answer's source).
    let word: VocabWord
    /// The prompt shown to the user (a definition, the word, or a sentence with a blank).
    let prompt: String
    /// Multiple-choice options (shuffled). For typed fill-blank this may be empty.
    let options: [String]
    /// The text considered correct (matched case/diacritic-insensitively for typed input).
    let answer: String
    /// Whether this question expects typed input rather than a choice.
    let isTyped: Bool

    /// Compares a user's answer to the correct one with trimming + case/diacritic folding.
    func isCorrect(_ given: String) -> Bool {
        QuizQuestion.normalize(given) == QuizQuestion.normalize(answer)
    }

    static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

/// The outcome of a graded answer, used to drive immediate feedback UI.
struct AnswerResult {
    let question: QuizQuestion
    let given: String
    let correct: Bool
    /// Mastery level before and after, so the UI can show "leveled up".
    let previousLevel: Int
    let newLevel: Int
    var leveledUp: Bool { newLevel > previousLevel }
}

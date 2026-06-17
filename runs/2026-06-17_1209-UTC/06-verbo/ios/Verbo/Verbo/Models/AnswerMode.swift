import Foundation

/// How the learner answers a drill prompt.
enum AnswerMode: String, CaseIterable, Identifiable, Codable {
    case type
    case choice

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .type: return "Type the answer"
        case .choice: return "Multiple choice"
        }
    }
}

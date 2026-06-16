import Foundation

/// The graded / study session modes Citizen offers.
enum ExamMode: String, CaseIterable, Identifiable, Codable {
    case mock          // 10 questions, pass at 6
    case quick         // 5 questions
    case category      // all questions in a chosen category
    case reviewFlagged // flagged or previously missed questions
    case adaptive      // weighted toward low-mastery questions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mock: return "Mock Exam"
        case .quick: return "Quick Quiz"
        case .category: return "By Category"
        case .reviewFlagged: return "Review Flagged"
        case .adaptive: return "Weak-Area Adaptive"
        }
    }

    var subtitle: String {
        switch self {
        case .mock: return "10 questions \u{00B7} pass at 6 of 10"
        case .quick: return "5 quick questions"
        case .category: return "Focus one civics category"
        case .reviewFlagged: return "Your flagged & missed questions"
        case .adaptive: return "Targets your weakest questions"
        }
    }

    var systemImage: String {
        switch self {
        case .mock: return "checkmark.seal"
        case .quick: return "bolt"
        case .category: return "square.grid.2x2"
        case .reviewFlagged: return "flag"
        case .adaptive: return "scope"
        }
    }

    /// Number of questions for the mode (category/flagged are variable; 0 = derive at runtime).
    var fixedCount: Int {
        switch self {
        case .mock: return 10
        case .quick: return 5
        case .category, .reviewFlagged, .adaptive: return 0
        }
    }

    /// The passing threshold for graded modes. Mock follows the official 6/10 rule.
    func passThreshold(total: Int) -> Int {
        switch self {
        case .mock:
            return 6
        default:
            // 60% rounded up, mirroring the spirit of the official test.
            guard total > 0 else { return 0 }
            return Int((Double(total) * 0.6).rounded(.up))
        }
    }

    /// Whether this mode requires Pro to run.
    var requiresPro: Bool {
        switch self {
        case .mock, .quick: return false
        case .category, .reviewFlagged, .adaptive: return true
        }
    }
}

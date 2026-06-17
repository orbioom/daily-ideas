import SwiftUI

/// The kinds of study sessions Parcel offers.
enum ExamMode: String, CaseIterable, Identifiable, Codable {
    case mock
    case quick
    case topic
    case review
    case adaptive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mock: return "Mock Exam"
        case .quick: return "Quick Quiz"
        case .topic: return "Topic Quiz"
        case .review: return "Review Missed"
        case .adaptive: return "Adaptive Drill"
        }
    }

    var subtitle: String {
        switch self {
        case .mock: return "Timed, exam-length practice test"
        case .quick: return "A short warm-up across all topics"
        case .topic: return "Focus on a single subject area"
        case .review: return "Re-test questions you missed or flagged"
        case .adaptive: return "Targets your weakest areas first"
        }
    }

    var systemImage: String {
        switch self {
        case .mock: return "doc.text.magnifyingglass"
        case .quick: return "bolt.fill"
        case .topic: return "square.grid.2x2"
        case .review: return "arrow.uturn.backward"
        case .adaptive: return "scope"
        }
    }

    /// Only the mock exam is timed and graded against the pass threshold.
    var isTimed: Bool { self == .mock }

    /// Whether this mode is part of the free tier.
    var isFree: Bool {
        switch self {
        case .quick, .topic: return true
        case .mock, .review, .adaptive: return false
        }
    }
}

import Foundation
import SwiftData

enum ExamMode: String, CaseIterable, Codable, Identifiable {
    case practiceCategory
    case quickMock
    case fullMock
    case review
    var id: String { rawValue }

    var label: String {
        switch self {
        case .practiceCategory: return "Category Practice"
        case .quickMock: return "Quick Mock"
        case .fullMock: return "Full Mock Exam"
        case .review: return "Review"
        }
    }
}

/// A completed session record (mock, practice, or review).
@Model
final class ExamResult {
    var date: Date
    var modeRaw: String
    var categoryRaw: String?
    var total: Int
    var correct: Int
    var passed: Bool
    var durationSec: Int
    var missedIDs: [Int]

    init(
        date: Date = .now,
        modeRaw: String,
        categoryRaw: String? = nil,
        total: Int,
        correct: Int,
        passed: Bool,
        durationSec: Int,
        missedIDs: [Int] = []
    ) {
        self.date = date
        self.modeRaw = modeRaw
        self.categoryRaw = categoryRaw
        self.total = total
        self.correct = correct
        self.passed = passed
        self.durationSec = durationSec
        self.missedIDs = missedIDs
    }

    var mode: ExamMode { ExamMode(rawValue: modeRaw) ?? .quickMock }
    var category: QuestionCategory? {
        guard let categoryRaw else { return nil }
        return QuestionCategory(rawValue: categoryRaw)
    }

    var scorePercent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total) * 100).rounded())
    }

    var durationText: String {
        let m = durationSec / 60
        let s = durationSec % 60
        return String(format: "%d:%02d", m, s)
    }
}

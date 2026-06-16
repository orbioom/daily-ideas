import Foundation
import SwiftData

/// A completed (or finished) graded session: mock exam, quick quiz, category, etc.
@Model
final class ExamResult {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Raw mode identifier; see `ExamMode.rawValue`.
    var mode: String
    var score: Int
    var total: Int
    var passed: Bool
    var durationSeconds: Int

    init(id: UUID = UUID(),
         date: Date = Date(),
         mode: String,
         score: Int,
         total: Int,
         passed: Bool,
         durationSeconds: Int) {
        self.id = id
        self.date = date
        self.mode = mode
        self.score = score
        self.total = total
        self.passed = passed
        self.durationSeconds = durationSeconds
    }

    /// Score as a 0...1 fraction. Guards division when total is 0.
    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(score) / Double(total)
    }

    /// Human-friendly mode label, falling back to the raw string if unknown.
    var modeLabel: String {
        ExamMode(rawValue: mode)?.title ?? mode.capitalized
    }
}

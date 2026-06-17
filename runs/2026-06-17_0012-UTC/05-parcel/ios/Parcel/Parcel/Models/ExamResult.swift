import Foundation
import SwiftData

/// A completed graded session: mock exam, quick quiz, topic quiz, adaptive, etc.
@Model
final class ExamResult {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Raw mode identifier; see `ExamMode.rawValue`.
    var modeRaw: String
    /// Optional topic identifier (set for `.topic` sessions); see `Topic.rawValue`.
    var topicRaw: String?
    var score: Int
    var total: Int
    var durationSeconds: Int
    var passed: Bool

    init(id: UUID = UUID(),
         date: Date = Date(),
         modeRaw: String,
         topicRaw: String? = nil,
         score: Int,
         total: Int,
         durationSeconds: Int,
         passed: Bool) {
        self.id = id
        self.date = date
        self.modeRaw = modeRaw
        self.topicRaw = topicRaw
        self.score = score
        self.total = total
        self.durationSeconds = durationSeconds
        self.passed = passed
    }

    /// Score as a 0...1 fraction. Guards division when total is 0.
    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(score) / Double(total)
    }

    /// Percent 0...100, rounded.
    var percent: Int { Int((fraction * 100).rounded()) }

    /// Human-friendly mode label, falling back to the raw string if unknown.
    var modeLabel: String {
        ExamMode(rawValue: modeRaw)?.title ?? modeRaw.capitalized
    }

    /// Resolved topic, if this was a topic session.
    var topic: Topic? {
        guard let topicRaw else { return nil }
        return Topic(rawValue: topicRaw)
    }
}

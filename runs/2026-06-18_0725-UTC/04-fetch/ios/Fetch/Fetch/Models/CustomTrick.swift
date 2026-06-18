import Foundation
import SwiftData

/// A user-authored trick (Pro feature). Persisted in SwiftData and surfaced in the
/// Library alongside the static catalog via a unified view model.
@Model
final class CustomTrick {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var difficultyRaw: Int
    var icon: String
    var summary: String
    /// Steps stored as newline-joined text to keep the model simple and portable.
    var stepsText: String
    var tipsText: String
    var estimatedDays: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: TrickCategory = .tricks,
        difficulty: Difficulty = .easy,
        icon: String = "pawprint.fill",
        summary: String = "",
        steps: [String] = [],
        tips: [String] = [],
        estimatedDays: Int = 7,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.icon = icon
        self.summary = summary
        self.stepsText = steps.joined(separator: "\n")
        self.tipsText = tips.joined(separator: "\n")
        self.estimatedDays = max(1, estimatedDays)
        self.createdAt = createdAt
    }

    var category: TrickCategory { TrickCategory(rawValue: categoryRaw) ?? .tricks }
    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .easy }

    var steps: [String] {
        stepsText.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }
    var tips: [String] {
        tipsText.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    /// A stable catalog-style id so progress/sessions can reference custom tricks too.
    var trickId: String { "custom-\(id.uuidString)" }

    /// Project into the same shape the rest of the app uses for catalog tricks.
    var asTrick: Trick {
        Trick(
            id: trickId,
            name: name,
            category: category,
            difficulty: difficulty,
            icon: icon,
            summary: summary.isEmpty ? "Your custom trick." : summary,
            steps: steps.isEmpty ? ["Add your training steps when editing this trick."] : steps,
            tips: tips,
            estimatedDays: estimatedDays,
            prerequisites: []
        )
    }
}

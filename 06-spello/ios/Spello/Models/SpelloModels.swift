import Foundation
import SwiftData

@Model
final class SpelloProfile {
    var id: UUID = UUID()
    var name: String = ""
    var gradeLevel: Int = 1   // 1–5
    var createdAt: Date = Date()

    init(name: String, gradeLevel: Int) {
        self.name = name
        self.gradeLevel = gradeLevel
    }
}

@Model
final class SpelloSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var profileId: UUID = UUID()
    var mode: String = "quiz"    // "quiz" | "fill" | "listen"
    var gradeLevel: Int = 1
    var totalWords: Int = 0
    var correctWords: Int = 0

    init(profileId: UUID, mode: String, gradeLevel: Int, totalWords: Int, correctWords: Int) {
        self.profileId = profileId
        self.mode = mode
        self.gradeLevel = gradeLevel
        self.totalWords = totalWords
        self.correctWords = correctWords
    }
}

@Model
final class SpelloPrefs {
    var onboardingDone: Bool = false
    var activeProfileId: UUID? = nil
    var hapticsEnabled: Bool = true
    var speechRate: Float = 0.45

    init() {}
}

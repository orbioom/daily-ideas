import Foundation
import SwiftData

enum PoseCategory: String, Codable, CaseIterable {
    case standing = "Standing"
    case seated = "Seated"
    case lying = "Lying Down"
    case balance = "Balance"
    case inversion = "Inversion"
    case twist = "Twist"
    case backbend = "Backbend"
    case restorative = "Restorative"
}

enum SessionDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum SessionFocus: String, Codable, CaseIterable {
    case morning = "Morning"
    case evening = "Evening"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case balance = "Balance"
    case stress = "Stress Relief"
    case core = "Core"
    case yin = "Yin"
    case restorative = "Restorative"
    case full = "Full Body"
}

struct YogaPose: Identifiable {
    let id: String
    let name: String
    let sanskrit: String
    let category: PoseCategory
    let emoji: String
    let durationSeconds: Int
    let benefits: [String]
    let instructions: [String]
    let breathCue: String
}

struct SessionStep: Identifiable {
    let id: UUID
    let pose: YogaPose
    let durationSeconds: Int
    let isTransition: Bool
    let cue: String
    let side: StepSide

    enum StepSide { case both, left, right }
}

struct YogaSession: Identifiable {
    let id: String
    let name: String
    let description: String
    let difficulty: SessionDifficulty
    let focus: SessionFocus
    let emoji: String
    let gradientColors: [String]
    let steps: [SessionStep]

    var totalDurationMinutes: Int {
        let secs = steps.reduce(0) { $0 + $1.durationSeconds }
        return max(1, secs / 60)
    }

    var poseCount: Int { steps.filter { !$0.isTransition }.count }
}

@Model
final class CompletedSession {
    var sessionId: String
    var sessionName: String
    var date: Date
    var durationMinutes: Int
    var moodBefore: Int
    var moodAfter: Int
    var notes: String

    init(sessionId: String, sessionName: String, durationMinutes: Int, moodBefore: Int = 3, moodAfter: Int = 3, notes: String = "") {
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.date = Date()
        self.durationMinutes = durationMinutes
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.notes = notes
    }
}

import SwiftUI

/// The primary muscle group an exercise trains.
enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case core, upper, lower, fullBody, cardio, mobility

    var id: String { rawValue }

    var label: String {
        switch self {
        case .core: return "Core"
        case .upper: return "Upper body"
        case .lower: return "Lower body"
        case .fullBody: return "Full body"
        case .cardio: return "Cardio"
        case .mobility: return "Mobility"
        }
    }

    var symbol: String {
        switch self {
        case .core: return "figure.core.training"
        case .upper: return "figure.strengthtraining.functional"
        case .lower: return "figure.step.training"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "figure.run"
        case .mobility: return "figure.flexibility"
        }
    }
}

/// Whether an exercise is counted in reps or held/performed for a duration.
enum ExerciseKind: String, CaseIterable, Identifiable, Codable {
    case reps, timed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reps: return "Reps"
        case .timed: return "Timed"
        }
    }
}

/// The category a workout belongs to — used for grouping and filtering.
enum WorkoutCategory: String, CaseIterable, Identifiable, Codable {
    case fullBody, core, upperBody, lowerBody, cardio, mobility

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fullBody: return "Full body"
        case .core: return "Core"
        case .upperBody: return "Upper body"
        case .lowerBody: return "Lower body"
        case .cardio: return "Cardio"
        case .mobility: return "Mobility"
        }
    }

    var symbol: String {
        switch self {
        case .fullBody: return "figure.mixed.cardio"
        case .core: return "figure.core.training"
        case .upperBody: return "figure.strengthtraining.functional"
        case .lowerBody: return "figure.step.training"
        case .cardio: return "figure.run"
        case .mobility: return "figure.flexibility"
        }
    }

    var tint: Color {
        switch self {
        case .fullBody: return Brand.magic
        case .core: return Brand.info
        case .upperBody: return Brand.warn
        case .lowerBody: return Brand.live
        case .cardio: return Brand.danger
        case .mobility: return Brand.text2
        }
    }
}

/// Relative intensity of a workout.
enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy, moderate, hard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        }
    }

    var tint: Color {
        switch self {
        case .easy: return Brand.live
        case .moderate: return Brand.warn
        case .hard: return Brand.danger
        }
    }
}

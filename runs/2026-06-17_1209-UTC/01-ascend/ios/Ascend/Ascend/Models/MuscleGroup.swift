import SwiftUI

/// Primary muscle group worked by an exercise.
enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest, back, legs, shoulders, arms, core

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .legs: return "Legs"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        }
    }

    var symbol: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .legs: return "figure.run"
        case .shoulders: return "figure.arms.open"
        case .arms: return "dumbbell.fill"
        case .core: return "figure.core.training"
        }
    }

    /// Distinct, AA-contrast hues for charts/badges in both schemes.
    var hue: Color {
        switch self {
        case .chest: return Color.dyn(0xC0492F, 0xE0795F)
        case .back: return Color.dyn(0x2F6FB0, 0x6FA8DC)
        case .legs: return Color.dyn(0x2F7D4F, 0x5FC487)
        case .shoulders: return Color.dyn(0x8A5A12, 0xF2A53C)
        case .arms: return Color.dyn(0x6A3FB0, 0xA98EE0)
        case .core: return Color.dyn(0xB0892F, 0xD8B760)
        }
    }
}

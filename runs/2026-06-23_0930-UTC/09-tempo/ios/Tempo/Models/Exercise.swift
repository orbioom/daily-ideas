import Foundation
import SwiftData

/// Primary muscle group for an exercise. Used for filtering and volume-by-group stats.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest, back, shoulders, quads, hamstrings, glutes, biceps, triceps, core, calves, forearms, fullBody

    var id: String { rawValue }

    var display: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }

    var symbol: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.strengthtraining.functional"
        case .shoulders: return "figure.boxing"
        case .quads: return "figure.run"
        case .hamstrings: return "figure.flexibility"
        case .glutes: return "figure.cooldown"
        case .biceps: return "dumbbell.fill"
        case .triceps: return "dumbbell"
        case .core: return "figure.core.training"
        case .calves: return "figure.walk"
        case .forearms: return "hand.raised.fill"
        case .fullBody: return "figure.strengthtraining.traditional"
        }
    }
}

/// Equipment category for an exercise.
enum Equipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell

    var id: String { rawValue }
    var display: String { rawValue.capitalized }

    /// Whether a plate calculator makes sense for this equipment.
    var usesPlates: Bool { self == .barbell }
}

/// A movement in the exercise library. Seeded with 40+ compound & accessory lifts.
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleRaw: String
    var equipmentRaw: String
    var notes: String
    var isFavorite: Bool
    var isCustom: Bool
    var createdAt: Date

    /// Inverse relationship: sets logged for this exercise across all workouts.
    @Relationship(deleteRule: .nullify, inverse: \SetEntry.exercise)
    var setEntries: [SetEntry]

    init(
        id: UUID = UUID(),
        name: String,
        muscle: MuscleGroup,
        equipment: Equipment,
        notes: String = "",
        isFavorite: Bool = false,
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.muscleRaw = muscle.rawValue
        self.equipmentRaw = equipment.rawValue
        self.notes = notes
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.setEntries = []
    }

    var muscle: MuscleGroup {
        get { MuscleGroup(rawValue: muscleRaw) ?? .fullBody }
        set { muscleRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }
}

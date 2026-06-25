import Foundation
import SwiftData

enum BreakType: String, Codable, CaseIterable, Identifiable {
    case beach = "Beach Break"
    case point = "Point Break"
    case reef = "Reef Break"
    case riverMouth = "River Mouth"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .beach: return "beach.umbrella.fill"
        case .point: return "arrow.turn.right.up"
        case .reef: return "water.waves"
        case .riverMouth: return "drop.fill"
        }
    }
}

enum SpotDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
}

@Model
final class SurfSpot {
    var id: UUID = UUID()
    var name: String = ""
    var breakType: BreakType = BreakType.beach
    var difficulty: SpotDifficulty = SpotDifficulty.intermediate
    var notes: String = ""
    var isFavorite: Bool = false
    var createdAt: Date = Date.now

    init(
        name: String,
        breakType: BreakType = .beach,
        difficulty: SpotDifficulty = .intermediate,
        notes: String = "",
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.breakType = breakType
        self.difficulty = difficulty
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = .now
    }
}

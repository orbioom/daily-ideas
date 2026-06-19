import Foundation
import SwiftData

enum TrailDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
    case expert = "Expert"

    var color: String {
        switch self {
        case .easy: return "green"
        case .moderate: return "blue"
        case .hard: return "orange"
        case .expert: return "red"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "leaf.fill"
        case .moderate: return "figure.walk"
        case .hard: return "mountain.2.fill"
        case .expert: return "flame.fill"
        }
    }
}

@Model
final class Trail {
    var id: UUID
    var name: String
    var location: String
    var trailDescription: String
    var distanceKm: Double
    var elevationGainM: Double
    var difficulty: TrailDifficulty
    var isFavorite: Bool
    var addedDate: Date
    @Relationship(deleteRule: .cascade) var sessions: [HikeSession]

    init(
        name: String,
        location: String = "",
        trailDescription: String = "",
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        difficulty: TrailDifficulty = .moderate,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.trailDescription = trailDescription
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.addedDate = Date()
        self.sessions = []
    }

    var sessionCount: Int { sessions.count }

    var lastHikedDate: Date? {
        sessions.map(\.date).max()
    }

    var bestRating: Int? {
        let rated = sessions.compactMap { $0.rating > 0 ? $0.rating : nil }
        return rated.max()
    }
}

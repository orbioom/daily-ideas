import Foundation
import SwiftData

enum TherapyType: String, CaseIterable, Codable, Identifiable {
    case sauna = "Sauna"
    case coldPlunge = "Cold Plunge"
    case steam = "Steam Room"
    case iceBath = "Ice Bath"
    case contrast = "Contrast"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .sauna: return "flame.fill"
        case .coldPlunge: return "drop.fill"
        case .steam: return "cloud.fill"
        case .iceBath: return "snowflake"
        case .contrast: return "arrow.up.arrow.down.circle.fill"
        }
    }

    var defaultTempCelsius: Double {
        switch self {
        case .sauna: return 80
        case .coldPlunge: return 10
        case .steam: return 45
        case .iceBath: return 5
        case .contrast: return 37
        }
    }

    var defaultDurationSeconds: Int {
        switch self {
        case .sauna: return 1200  // 20 min
        case .coldPlunge: return 180  // 3 min
        case .steam: return 900   // 15 min
        case .iceBath: return 180  // 3 min
        case .contrast: return 1800 // 30 min
        }
    }

    var isHot: Bool { self == .sauna || self == .steam }
}

@Model
final class TherapySession {
    var id: UUID
    var date: Date
    var typeRaw: String
    var durationSeconds: Int
    var temperatureCelsius: Double
    var rounds: Int
    var rating: Int
    var notes: String

    init(
        type: TherapyType = .sauna,
        durationSeconds: Int = 1200,
        temperatureCelsius: Double = 80,
        rounds: Int = 1,
        rating: Int = 3,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = Date()
        self.typeRaw = type.rawValue
        self.durationSeconds = durationSeconds
        self.temperatureCelsius = temperatureCelsius
        self.rounds = rounds
        self.rating = rating
        self.notes = notes
    }

    var type: TherapyType { TherapyType(rawValue: typeRaw) ?? .sauna }
    var durationMinutes: Double { Double(durationSeconds) / 60.0 }
}

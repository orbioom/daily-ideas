import SwiftData
import Foundation

enum SessionType: String, CaseIterable, Codable {
    case shadowBoxing = "Shadow Boxing"
    case bagWork = "Bag Work"
    case padWork = "Pad Work"
    case sparring = "Sparring"
    case mitts = "Mitts"
    case conditioning = "Conditioning"
    case drills = "Drills"
    case technicalDrills = "Technical Drills"

    var icon: String {
        switch self {
        case .shadowBoxing: return "figure.boxing"
        case .bagWork: return "bag.fill"
        case .padWork: return "hand.raised.fill"
        case .sparring: return "figure.martial.arts"
        case .mitts: return "hands.clap.fill"
        case .conditioning: return "heart.fill"
        case .drills: return "repeat.circle.fill"
        case .technicalDrills: return "gearshape.fill"
        }
    }

    var colorName: String {
        switch self {
        case .shadowBoxing: return "blue"
        case .bagWork: return "red"
        case .padWork: return "orange"
        case .sparring: return "purple"
        case .mitts: return "green"
        case .conditioning: return "pink"
        case .drills: return "cyan"
        case .technicalDrills: return "indigo"
        }
    }
}

enum SessionIntensity: Int, CaseIterable, Codable {
    case light = 1, moderate, hard, veryHard, max

    var label: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        case .max: return "Max"
        }
    }

    var color: String {
        switch self {
        case .light: return "green"
        case .moderate: return "yellow"
        case .hard: return "orange"
        case .veryHard: return "red"
        case .max: return "purple"
        }
    }
}

@Model
final class TrainingSession {
    var id: UUID
    var date: Date
    var sessionTypeRaw: String
    var durationMinutes: Int
    var rounds: Int
    var roundDurationSeconds: Int
    var intensityRaw: Int
    var focusAreas: String
    var notes: String
    var mood: Int
    var partnerName: String

    init(
        date: Date = Date(),
        sessionType: SessionType = .shadowBoxing,
        durationMinutes: Int,
        rounds: Int = 0,
        roundDurationSeconds: Int = 180,
        intensity: SessionIntensity = .moderate,
        focusAreas: String = "",
        notes: String = "",
        mood: Int = 3,
        partnerName: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.sessionTypeRaw = sessionType.rawValue
        self.durationMinutes = durationMinutes
        self.rounds = rounds
        self.roundDurationSeconds = roundDurationSeconds
        self.intensityRaw = intensity.rawValue
        self.focusAreas = focusAreas
        self.notes = notes
        self.mood = mood
        self.partnerName = partnerName
    }

    var sessionType: SessionType {
        get { SessionType(rawValue: sessionTypeRaw) ?? .shadowBoxing }
        set { sessionTypeRaw = newValue.rawValue }
    }

    var intensity: SessionIntensity {
        get { SessionIntensity(rawValue: intensityRaw) ?? .moderate }
        set { intensityRaw = newValue.rawValue }
    }

    var roundsDisplay: String { rounds > 0 ? "\(rounds)×\(roundDurationSeconds / 60)min" : "--" }
    var durationDisplay: String { "\(durationMinutes) min" }
}

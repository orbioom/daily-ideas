import Foundation
import SwiftData

/// One monitored night of sleep.
@Model
final class NightSession {
    var startedAt: Date
    var endedAt: Date
    /// Normalized loudness (0...1) averaged per minute, for the night chart.
    var levelSamples: [Double]
    /// 1–5 "how do you feel" rating logged at wake-up. 0 = not rated.
    var morningRating: Int
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \SnoreEpisode.session)
    var episodes: [SnoreEpisode]
    var factors: [SleepFactor]

    init(startedAt: Date, endedAt: Date, levelSamples: [Double] = [],
         morningRating: Int = 0, notes: String = "",
         episodes: [SnoreEpisode] = [], factors: [SleepFactor] = []) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.levelSamples = levelSamples
        self.morningRating = morningRating
        self.notes = notes
        self.episodes = episodes
        self.factors = factors
    }

    var duration: TimeInterval { max(endedAt.timeIntervalSince(startedAt), 0) }
}

/// A detected stretch of snoring within a night.
@Model
final class SnoreEpisode {
    /// Seconds from session start.
    var startOffset: TimeInterval
    var duration: TimeInterval
    /// Peak level in decibels relative to full scale (-160...0).
    var peakDB: Double
    var intensityRaw: String
    var session: NightSession?

    init(startOffset: TimeInterval, duration: TimeInterval, peakDB: Double, intensity: SnoreIntensity) {
        self.startOffset = startOffset
        self.duration = duration
        self.peakDB = peakDB
        self.intensityRaw = intensity.rawValue
    }

    var intensity: SnoreIntensity { SnoreIntensity(rawValue: intensityRaw) ?? .mild }
}

enum SnoreIntensity: String, CaseIterable, Codable {
    case mild, loud, epic

    var label: String {
        switch self {
        case .mild: return "Mild"
        case .loud: return "Loud"
        case .epic: return "Epic"
        }
    }
    /// Weight used by the Snore Score formula.
    var weight: Double {
        switch self {
        case .mild: return 0.4
        case .loud: return 1.0
        case .epic: return 1.6
        }
    }
}

/// Something you did (or used) before bed — alcohol, mouth tape, side sleeping…
@Model
final class SleepFactor {
    @Attribute(.unique) var name: String
    var emoji: String
    var isBuiltIn: Bool
    /// Whether this factor is offered in the pre-sleep checklist.
    var isActive: Bool
    @Relationship(inverse: \NightSession.factors)
    var sessions: [NightSession]

    init(name: String, emoji: String, isBuiltIn: Bool = false, isActive: Bool = true) {
        self.name = name
        self.emoji = emoji
        self.isBuiltIn = isBuiltIn
        self.isActive = isActive
        self.sessions = []
    }

    static let builtIns: [(String, String)] = [
        ("Alcohol", "🍷"), ("Late meal", "🍕"), ("Caffeine after 2pm", "☕️"),
        ("Mouth tape", "😮‍💨"), ("Nasal strip", "🩹"), ("Slept on side", "🛌"),
        ("Exercised today", "🏃"), ("Stuffy nose", "🤧"), ("Humidifier on", "💨"),
        ("Stressful day", "😣"),
    ]
}

import SwiftUI

/// Five-level mood scale. Stored on `Moment` as `moodRaw: Int`.
enum Mood: Int, CaseIterable, Identifiable, Codable {
    case rough = 0
    case low = 1
    case neutral = 2
    case good = 3
    case great = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .rough: return "Rough"
        case .low: return "Low"
        case .neutral: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }

    var symbol: String {
        switch self {
        case .rough: return "cloud.rain.fill"
        case .low: return "cloud.fill"
        case .neutral: return "cloud.sun.fill"
        case .good: return "sun.max.fill"
        case .great: return "sparkles"
        }
    }

    /// Mood-coded hue used for dots, chips and the calendar.
    var color: Color {
        switch self {
        case .rough: return Color.dyn(0x8E6FB0, 0xB89BD8)
        case .low: return Color.dyn(0x5C86C0, 0x8FB2E6)
        case .neutral: return Color.dyn(0xCBA94B, 0xE6C975)
        case .good: return Color.dyn(0xE08A4E, 0xF2A86E)
        case .great: return Color.dyn(0xE0567E, 0xF286A4)
        }
    }

    static func from(_ raw: Int) -> Mood {
        Mood(rawValue: raw) ?? .neutral
    }
}

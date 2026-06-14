import SwiftUI

// MARK: - Ambient soundscapes
enum Ambient: String, CaseIterable, Identifiable, Codable {
    case none
    case brownNoise
    case rain
    case drone
    case ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Silence"
        case .brownNoise: return "Brown Noise"
        case .rain: return "Rain"
        case .drone: return "Drone"
        case .ocean: return "Ocean"
        }
    }

    var symbol: String {
        switch self {
        case .none: return "speaker.slash"
        case .brownNoise: return "waveform"
        case .rain: return "cloud.rain"
        case .drone: return "dot.radiowaves.left.and.right"
        case .ocean: return "water.waves"
        }
    }

    /// Free tier: silence + brown noise. Rest are Pro.
    var isPro: Bool {
        switch self {
        case .none, .brownNoise: return false
        case .rain, .drone, .ocean: return true
        }
    }
}

// MARK: - Bell tones
enum BellTone: String, CaseIterable, Identifiable, Codable {
    case bowl
    case chime
    case gong

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bowl: return "Singing Bowl"
        case .chime: return "Chime"
        case .gong: return "Gong"
        }
    }

    var symbol: String {
        switch self {
        case .bowl: return "bell"
        case .chime: return "bell.badge"
        case .gong: return "circle.circle"
        }
    }

    /// Free tier: bowl only.
    var isPro: Bool { self != .bowl }

    /// Additive partials: (frequency Hz, relative amplitude, decay rate).
    var partials: [(freq: Double, amp: Double, decay: Double)] {
        switch self {
        case .bowl:
            return [(220, 1.0, 1.6), (440, 0.55, 2.1), (660, 0.30, 2.8), (880, 0.16, 3.6)]
        case .chime:
            return [(880, 1.0, 3.0), (1320, 0.5, 3.6), (1760, 0.28, 4.4), (2640, 0.12, 5.2)]
        case .gong:
            return [(110, 1.0, 0.9), (165, 0.7, 1.2), (277, 0.5, 1.6), (415, 0.35, 2.2), (550, 0.2, 2.8)]
        }
    }

    /// Bell render length in seconds.
    var duration: Double {
        switch self {
        case .bowl: return 3.2
        case .chime: return 2.4
        case .gong: return 4.0
        }
    }
}

// MARK: - Mood after a sit
enum Mood: String, CaseIterable, Identifiable, Codable {
    case calm
    case restless
    case focused
    case sleepy
    case grateful

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calm: return "Calm"
        case .restless: return "Restless"
        case .focused: return "Focused"
        case .sleepy: return "Sleepy"
        case .grateful: return "Grateful"
        }
    }

    var emoji: String {
        switch self {
        case .calm: return "🌿"
        case .restless: return "🌊"
        case .focused: return "🎯"
        case .sleepy: return "🌙"
        case .grateful: return "🙏"
        }
    }

    var color: Color {
        switch self {
        case .calm: return Color(hex: 0x2FA08C)
        case .restless: return Color(hex: 0xC0503E)
        case .focused: return Color(hex: 0x3E72C0)
        case .sleepy: return Color(hex: 0x7A5EC0)
        case .grateful: return Color(hex: 0xC08A3E)
        }
    }
}

// MARK: - Time of day buckets (insights)
enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case night

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        }
    }

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }
}

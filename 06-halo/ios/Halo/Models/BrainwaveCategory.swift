import SwiftUI

enum BrainwaveCategory: String, CaseIterable, Codable, Identifiable {
    case delta = "Delta"
    case theta = "Theta"
    case alpha = "Alpha"
    case beta = "Beta"
    case gamma = "Gamma"

    var id: String { rawValue }

    var frequencyRange: String {
        switch self {
        case .delta: return "0.5–4 Hz"
        case .theta: return "4–8 Hz"
        case .alpha: return "8–14 Hz"
        case .beta:  return "14–30 Hz"
        case .gamma: return "30–100 Hz"
        }
    }

    var color: Color {
        switch self {
        case .delta: return Color(hex: "#4A90D9")
        case .theta: return Color(hex: "#7B5EA7")
        case .alpha: return Color(hex: "#C084FC")
        case .beta:  return Color(hex: "#F59E0B")
        case .gamma: return Color(hex: "#EF4444")
        }
    }

    var useCase: String {
        switch self {
        case .delta: return "Deep sleep & healing"
        case .theta: return "Meditation & creativity"
        case .alpha: return "Relaxed focus & calm"
        case .beta:  return "Alertness & concentration"
        case .gamma: return "Peak performance & memory"
        }
    }

    var description: String {
        switch self {
        case .delta:
            return "Delta waves (0.5–4 Hz) are the slowest brainwaves, dominant during deep dreamless sleep and deep meditation. They are associated with healing, regeneration, and the unconscious mind."
        case .theta:
            return "Theta waves (4–8 Hz) appear during deep meditation, light sleep, and the hypnagogic state. They are linked to creativity, intuition, and vivid imagery."
        case .alpha:
            return "Alpha waves (8–14 Hz) bridge conscious and subconscious. They are present when you're relaxed yet alert — the ideal state for learning, positive thinking, and stress reduction."
        case .beta:
            return "Beta waves (14–30 Hz) are associated with normal waking consciousness. Higher beta is linked to anxiety; mid-range beta supports focused thinking, problem-solving, and active attention."
        case .gamma:
            return "Gamma waves (30–100 Hz) are the fastest brainwaves, associated with higher cognitive functions, memory binding, and peak mental states. 40 Hz gamma is the subject of ongoing neurological research."
        }
    }

    var icon: String {
        switch self {
        case .delta: return "moon.fill"
        case .theta: return "sparkles"
        case .alpha: return "leaf.fill"
        case .beta:  return "bolt.fill"
        case .gamma: return "star.fill"
        }
    }
}

extension Color {
    // Only defined in HaloTheme, but referenced here
}

import SwiftUI

/// The catalog of on-device synthesized sounds. Every case maps to a pure-DSP
/// generator (see `Engine/Generators.swift`) — there are NO audio files anywhere.
/// Raw values are stable strings persisted in SwiftData (`MixLayer.soundTypeRaw`).
enum SoundType: String, CaseIterable, Identifiable, Codable {
    case white
    case pink
    case brown
    case rain
    case ocean
    case wind
    case stream
    case fan
    case fire
    case night

    var id: String { rawValue }

    /// Human-facing name shown on tiles and summaries.
    var title: String {
        switch self {
        case .white:  return "White Noise"
        case .pink:   return "Pink Noise"
        case .brown:  return "Brown Noise"
        case .rain:   return "Rain"
        case .ocean:  return "Ocean Waves"
        case .wind:   return "Wind"
        case .stream: return "Stream"
        case .fan:    return "Fan / Hum"
        case .fire:   return "Campfire"
        case .night:  return "Night Crickets"
        }
    }

    /// A short descriptor for accessibility hints and the mix summary.
    var blurb: String {
        switch self {
        case .white:  return "Even, full-spectrum static — masks sudden noises."
        case .pink:   return "Softer, balanced static that's easy on the ears."
        case .brown:  return "Deep, low rumble — like distant surf or a waterfall."
        case .rain:   return "Steady rainfall with scattered droplets."
        case .ocean:  return "Slow swelling waves rolling in and out."
        case .wind:   return "Gusting wind through an open space."
        case .stream: return "A bubbling brook over stones."
        case .fan:    return "A low fan whir with a faint room hum."
        case .fire:   return "A crackling campfire with soft pops."
        case .night:  return "A warm summer night of chirping crickets."
        }
    }

    /// SF Symbol used on the tile.
    var symbol: String {
        switch self {
        case .white:  return "waveform"
        case .pink:   return "waveform.path"
        case .brown:  return "waveform.path.ecg"
        case .rain:   return "cloud.rain.fill"
        case .ocean:  return "water.waves"
        case .wind:   return "wind"
        case .stream: return "drop.fill"
        case .fan:    return "fanblades.fill"
        case .fire:   return "flame.fill"
        case .night:  return "moon.stars.fill"
        }
    }

    /// Per-sound accent tint for the tile glow (resolved against the theme).
    var tint: Color {
        switch self {
        case .white, .pink, .brown:
            return HushTheme.teal
        case .rain, .stream, .ocean:
            return Color(red: 0x4D / 255.0, green: 0x9E / 255.0, blue: 0xC9 / 255.0)
        case .wind, .night:
            return HushTheme.indigo
        case .fan:
            return HushTheme.teal
        case .fire:
            return HushTheme.amber
        }
    }

    /// A pleasant default starting volume when a sound is first enabled (0…1).
    var defaultVolume: Double {
        switch self {
        case .white:  return 0.45
        case .pink:   return 0.5
        case .brown:  return 0.55
        case .rain:   return 0.6
        case .ocean:  return 0.6
        case .wind:   return 0.5
        case .stream: return 0.55
        case .fan:    return 0.55
        case .fire:   return 0.6
        case .night:  return 0.5
        }
    }

    /// Whether this sound is available on the free tier.
    /// Free: the three core noises plus three ambient generators.
    var isFreeTier: Bool {
        switch self {
        case .white, .pink, .brown, .rain, .ocean, .fan:
            return true
        case .wind, .stream, .fire, .night:
            return false
        }
    }
}

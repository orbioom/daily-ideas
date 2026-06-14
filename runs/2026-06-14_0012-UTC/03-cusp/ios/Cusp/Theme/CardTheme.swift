import SwiftUI

/// The eight gradient card themes. Each is a pair of light/dark gradient stops
/// plus an "on-gradient" ink color tuned for contrast in both modes.
/// Stored on `CountdownEvent` as `colorTag` (0..7).
enum CardTheme: Int, CaseIterable, Identifiable {
    case coral = 0
    case dusk
    case ocean
    case forest
    case plum
    case amber
    case slate
    case rose

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .coral:  return "Coral"
        case .dusk:   return "Dusk"
        case .ocean:  return "Ocean"
        case .forest: return "Forest"
        case .plum:   return "Plum"
        case .amber:  return "Amber"
        case .slate:  return "Slate"
        case .rose:   return "Rose"
        }
    }

    /// Whether this theme is available on the free tier (first three).
    var isFree: Bool { rawValue < 3 }

    /// Gradient stops (top-leading -> bottom-trailing). Light then dark variants.
    private var stops: (lightTop: UInt, lightBottom: UInt, darkTop: UInt, darkBottom: UInt) {
        switch self {
        case .coral:  return (0xF6A07A, 0xE0613E, 0x8C3A26, 0x52201A)
        case .dusk:   return (0xF1A5B8, 0xB16FB8, 0x6E3A78, 0x3A2350)
        case .ocean:  return (0x6FC2E0, 0x3E7BC0, 0x265C8C, 0x16304F)
        case .forest: return (0x86C98E, 0x3E9E73, 0x2C6E54, 0x163A2C)
        case .plum:   return (0xB58CD6, 0x6E4AA8, 0x4A2F70, 0x281842)
        case .amber:  return (0xF6CE7A, 0xE0A03E, 0x8C6526, 0x523A16)
        case .slate:  return (0x9AA6B8, 0x5C6B82, 0x3A4456, 0x20252F)
        case .rose:   return (0xF3A0A8, 0xD45C6E, 0x8C3A45, 0x521E26)
        }
    }

    /// The gradient for cards. Adapts to color scheme via `Color.dyn`.
    var gradient: LinearGradient {
        let s = stops
        return LinearGradient(
            colors: [Color.dyn(s.lightTop, s.darkTop),
                     Color.dyn(s.lightBottom, s.darkBottom)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A soft, low-saturation tint of this theme for chips / dots on neutral surfaces.
    var dot: Color {
        let s = stops
        return Color.dyn(s.lightBottom, s.darkTop)
    }

    /// High-contrast ink to place over the gradient (near-white in both modes).
    var onGradient: Color { Color.dyn(0xFFFFFF, 0xF6F1EE) }

    /// Slightly translucent ink for secondary text on the gradient.
    var onGradientSoft: Color { Color.white.opacity(0.82) }

    static func from(_ tag: Int) -> CardTheme {
        CardTheme(rawValue: ((tag % 8) + 8) % 8) ?? .coral
    }
}

import SwiftUI

enum FoodCategory: String, CaseIterable, Identifiable, Codable {
    case chicken = "Chicken"
    case beefPork = "Beef & Pork"
    case seafood = "Seafood"
    case veg = "Vegetables"
    case frozen = "Frozen"
    case snacks = "Snacks & Other"
    case baked = "Baked"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chicken: return "🍗"
        case .beefPork: return "🥩"
        case .seafood: return "🍤"
        case .veg: return "🥦"
        case .frozen: return "🧊"
        case .snacks: return "🥨"
        case .baked: return "🍪"
        }
    }

    var tint: Color {
        switch self {
        case .chicken: return Color.dyn(0xE8541C, 0xFF8A3D)
        case .beefPork: return Color.dyn(0xB23A48, 0xF07A86)
        case .seafood: return Color.dyn(0x2D7DA6, 0x6CBEE0)
        case .veg: return Color.dyn(0x4C8C3A, 0x83D06A)
        case .frozen: return Color.dyn(0x4E7AC7, 0x8FB2EE)
        case .snacks: return Color.dyn(0xB07A1E, 0xE3B252)
        case .baked: return Color.dyn(0xA15B2E, 0xDB9863)
        }
    }
}

/// A single cooking variant (temperature + time + flip reminder) for a food.
struct CookVariant: Hashable {
    let tempF: Int
    let minutes: Int
    /// Minute mark at which to shake / flip. `nil` if not needed.
    let shakeOrFlipAtMin: Int?
}

/// Static catalog entry. NOT a SwiftData @Model — this is fixed reference data.
struct Food: Identifiable, Hashable {
    let id: String
    let name: String
    let category: FoodCategory
    /// SF Symbol or emoji shown on the food card.
    let icon: String

    /// Default (fresh) cooking values.
    let fresh: CookVariant
    /// Optional from-frozen values when meaningfully different.
    let frozen: CookVariant?

    /// Reference portion used for scaling math.
    let basePortionLabel: String
    let basePortionGrams: Double

    let notes: String
    /// USDA-safe / preferred internal temperature in °F, for meats. `nil` for non-meat.
    let targetInternalTempF: Int?

    var hasFrozenVariant: Bool { frozen != nil }

    /// Returns the appropriate variant for the requested state, falling back to fresh.
    func variant(frozen wantsFrozen: Bool) -> CookVariant {
        if wantsFrozen, let f = frozen { return f }
        return fresh
    }
}

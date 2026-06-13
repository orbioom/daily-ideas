import SwiftUI

/// The four Stoic cardinal virtues. Each carries a one-line definition and an
/// SF Symbol used across the Today, Reflect and Library screens.
enum Virtue: String, CaseIterable, Identifiable, Codable {
    case wisdom = "Wisdom"
    case justice = "Justice"
    case courage = "Courage"
    case temperance = "Temperance"

    var id: String { rawValue }

    /// A concise, classical definition of the virtue.
    var definition: String {
        switch self {
        case .wisdom:     return "Seeing things as they are, and judging well what is good, bad, or indifferent."
        case .justice:    return "Treating others fairly, keeping faith, and giving each their due."
        case .courage:    return "Meeting hardship, fear, and duty with steadiness rather than flight."
        case .temperance:  return "Moderation in desire and appetite; mastery of oneself."
        }
    }

    /// The Greek root often paired with the virtue, for flavour in the library.
    var greek: String {
        switch self {
        case .wisdom:     return "Sophia"
        case .justice:    return "Dikaiosyne"
        case .courage:    return "Andreia"
        case .temperance:  return "Sophrosyne"
        }
    }

    var icon: String {
        switch self {
        case .wisdom:     return "brain.head.profile"
        case .justice:    return "scalemass.fill"
        case .courage:    return "flame.fill"
        case .temperance:  return "drop.fill"
        }
    }

    var tint: Color {
        switch self {
        case .wisdom:     return Color.dyn(0x4A6FA5, 0x7FA8D8)
        case .justice:    return Color.dyn(0x7A6A3A, 0xC9B36A)
        case .courage:    return Color.dyn(0xA0432F, 0xCB6B52)
        case .temperance:  return Color.dyn(0x4F7A5A, 0x6FBE8C)
        }
    }
}

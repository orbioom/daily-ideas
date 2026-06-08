import SwiftUI

/// The kind of a time block. Stored on the model as a raw string so it is
/// stable across launches; each case carries its own color and SF Symbol.
enum BlockCategory: String, CaseIterable, Identifiable, Codable {
    case work, focus, health, personal, social, errands, learning, rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:     return "Work"
        case .focus:    return "Deep Focus"
        case .health:   return "Health"
        case .personal: return "Personal"
        case .social:   return "Social"
        case .errands:  return "Errands"
        case .learning: return "Learning"
        case .rest:     return "Rest"
        }
    }

    var icon: String {
        switch self {
        case .work:     return "briefcase.fill"
        case .focus:    return "scope"
        case .health:   return "heart.fill"
        case .personal: return "person.fill"
        case .social:   return "person.2.fill"
        case .errands:  return "bag.fill"
        case .learning: return "book.fill"
        case .rest:     return "moon.zzz.fill"
        }
    }

    /// Mid-tone colors chosen to read on both light and dark surfaces.
    var color: Color {
        switch self {
        case .work:     return Color(hex: 0x5E63A6)
        case .focus:    return Color(hex: 0x3E9E78)
        case .health:   return Color(hex: 0xC0553E)
        case .personal: return Color(hex: 0x4E6BA8)
        case .social:   return Color(hex: 0xC08A3E)
        case .errands:  return Color(hex: 0x8B6FB0)
        case .learning: return Color(hex: 0x3E8F9E)
        case .rest:     return Color(hex: 0x6E7287)
        }
    }
}

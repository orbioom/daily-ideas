import SwiftUI

/// The thematic category a phrase belongs to. Stored as a raw string on `Phrase`.
enum PhraseCategory: String, CaseIterable, Identifiable, Codable {
    case greetings
    case dining
    case directions
    case emergencies
    case shopping
    case basics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .greetings: return "Greetings"
        case .dining: return "Dining"
        case .directions: return "Directions"
        case .emergencies: return "Emergencies"
        case .shopping: return "Shopping"
        case .basics: return "Basics"
        }
    }

    var symbol: String {
        switch self {
        case .greetings: return "hand.wave.fill"
        case .dining: return "fork.knife"
        case .directions: return "map.fill"
        case .emergencies: return "cross.case.fill"
        case .shopping: return "bag.fill"
        case .basics: return "text.bubble.fill"
        }
    }

    var tint: Color {
        switch self {
        case .greetings: return Theme.brand
        case .dining: return Theme.warn
        case .directions: return Theme.brandDeep
        case .emergencies: return .red
        case .shopping: return .purple
        case .basics: return Theme.success
        }
    }
}

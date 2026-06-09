import Foundation
import SwiftUI

/// The intent of a prayer entry.
enum PrayerCategory: String, CaseIterable, Identifiable, Codable {
    case gratitude, petition, intercession, praise, confession, guidance

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gratitude: return "Gratitude"
        case .petition: return "Petition"
        case .intercession: return "Intercession"
        case .praise: return "Praise"
        case .confession: return "Confession"
        case .guidance: return "Guidance"
        }
    }

    var symbol: String {
        switch self {
        case .gratitude: return "heart"
        case .petition: return "hands.sparkles"
        case .intercession: return "person.2"
        case .praise: return "sparkles"
        case .confession: return "leaf"
        case .guidance: return "signpost.right"
        }
    }

    var tint: Color {
        switch self {
        case .gratitude: return Brand.live
        case .petition: return Brand.info
        case .intercession: return Brand.magic
        case .praise: return Brand.warn
        case .confession: return Brand.text2
        case .guidance: return Brand.danger
        }
    }
}

/// The lifecycle status of a prayer.
enum PrayerStatus: String, CaseIterable, Identifiable, Codable {
    case praying, answered, archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .praying: return "Praying"
        case .answered: return "Answered"
        case .archived: return "Archived"
        }
    }

    var symbol: String {
        switch self {
        case .praying: return "hands.sparkles"
        case .answered: return "checkmark.seal"
        case .archived: return "archivebox"
        }
    }

    var tint: Color {
        switch self {
        case .praying: return Brand.info
        case .answered: return Brand.live
        case .archived: return Brand.text3
        }
    }
}

/// The thematic thread of a devotion.
enum DevotionTheme: String, CaseIterable, Identifiable, Codable {
    case trust, gratitude, peace, hope, strength, love, forgiveness, guidance, patience, joy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .trust: return "Trust"
        case .gratitude: return "Gratitude"
        case .peace: return "Peace"
        case .hope: return "Hope"
        case .strength: return "Strength"
        case .love: return "Love"
        case .forgiveness: return "Forgiveness"
        case .guidance: return "Guidance"
        case .patience: return "Patience"
        case .joy: return "Joy"
        }
    }

    var symbol: String {
        switch self {
        case .trust: return "hand.raised"
        case .gratitude: return "heart"
        case .peace: return "leaf"
        case .hope: return "sunrise"
        case .strength: return "mountain.2"
        case .love: return "heart.circle"
        case .forgiveness: return "arrow.triangle.2.circlepath"
        case .guidance: return "signpost.right"
        case .patience: return "hourglass"
        case .joy: return "sparkles"
        }
    }
}

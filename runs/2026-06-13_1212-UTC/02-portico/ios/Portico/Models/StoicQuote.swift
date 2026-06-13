import SwiftUI

/// A single public-domain Stoic quotation.
struct StoicQuote: Identifiable, Hashable {
    let id: String
    let text: String
    let author: String
    let source: String
    let themeRaw: String

    var theme: QuoteTheme { QuoteTheme(rawValue: themeRaw) ?? .virtue }
}

/// Thematic groupings used by the Library filter chips.
enum QuoteTheme: String, CaseIterable, Identifiable {
    case control = "Control"
    case mortality = "Mortality"
    case virtue = "Virtue"
    case adversity = "Adversity"
    case time = "Time"
    case anger = "Anger"
    case gratitude = "Gratitude"
    case desire = "Desire"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .control:   return "hand.raised.fill"
        case .mortality: return "hourglass"
        case .virtue:    return "laurel.leading"
        case .adversity: return "mountain.2.fill"
        case .time:      return "clock.fill"
        case .anger:     return "flame"
        case .gratitude: return "heart.fill"
        case .desire:    return "sparkles"
        }
    }
}

/// The authors carried by the library, for the author filter.
enum QuoteAuthor: String, CaseIterable, Identifiable {
    case all = "All"
    case marcus = "Marcus Aurelius"
    case epictetus = "Epictetus"
    case seneca = "Seneca"

    var id: String { rawValue }
}

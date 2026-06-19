import SwiftUI

struct MemoirTheme {
    // MARK: - Brand Colors
    static let warmAmber   = Color(red: 0.87, green: 0.60, blue: 0.20)
    static let parchment   = Color(red: 0.97, green: 0.93, blue: 0.84)
    static let inkBrown    = Color(red: 0.32, green: 0.20, blue: 0.10)
    static let forestGreen = Color(red: 0.22, green: 0.48, blue: 0.22)

    // MARK: - Era Colors
    static func eraColor(_ era: LifeEra) -> Color {
        switch era {
        case .childhood:  return Color(red: 0.95, green: 0.70, blue: 0.30)
        case .teen:       return Color(red: 0.50, green: 0.75, blue: 0.90)
        case .youngAdult: return Color(red: 0.55, green: 0.80, blue: 0.55)
        case .adult:      return Color(red: 0.70, green: 0.50, blue: 0.85)
        case .recent:     return Color(red: 0.90, green: 0.55, blue: 0.55)
        case .reflection: return Color(red: 0.60, green: 0.70, blue: 0.75)
        }
    }

    // MARK: - Mood Colors
    static func moodColor(_ mood: EntryMood) -> Color {
        switch mood {
        case .joyful:      return Color(red: 1.00, green: 0.85, blue: 0.20)
        case .nostalgic:   return Color(red: 0.80, green: 0.65, blue: 0.45)
        case .bittersweet: return Color(red: 0.75, green: 0.70, blue: 0.85)
        case .proud:       return Color(red: 0.95, green: 0.65, blue: 0.25)
        case .reflective:  return Color(red: 0.55, green: 0.65, blue: 0.80)
        case .grateful:    return Color(red: 0.90, green: 0.45, blue: 0.55)
        }
    }

    // MARK: - Mood Icons
    static func moodIcon(_ mood: EntryMood) -> String {
        mood.icon
    }

    // MARK: - Typography helpers
    static let bodyFont = Font.system(.body, design: .serif)
    static let titleFont = Font.system(.title2, design: .serif).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .serif)
    static let captionFont = Font.system(.caption, design: .rounded)
}

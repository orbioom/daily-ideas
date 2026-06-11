import SwiftUI

enum MurmurTheme {
    static let accent = Color(red: 0.55, green: 0.30, blue: 0.85)
    static let recordRed = Color(red: 0.90, green: 0.25, blue: 0.30)
    static let waveformActive = Color(red: 0.55, green: 0.30, blue: 0.85)
    static let waveformIdle = Color.secondary.opacity(0.3)

    static func moodColor(_ mood: Mood) -> Color {
        switch mood {
        case .great:   return Color(red: 0.20, green: 0.78, blue: 0.45)
        case .good:    return Color(red: 0.35, green: 0.65, blue: 0.95)
        case .neutral: return Color(red: 0.65, green: 0.65, blue: 0.65)
        case .low:     return Color(red: 0.95, green: 0.70, blue: 0.25)
        case .rough:   return Color(red: 0.90, green: 0.35, blue: 0.35)
        }
    }

    static let bodyFont    = Font.system(size: 15, design: .serif)
    static let captionFont = Font.system(size: 12, weight: .medium, design: .rounded)
}

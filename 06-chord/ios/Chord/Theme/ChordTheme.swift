import SwiftUI

struct ChordTheme {
    static let teal = Color(red: 0.09, green: 0.63, blue: 0.60)
    static let deepTeal = Color(red: 0.04, green: 0.42, blue: 0.40)
    static let amber = Color(red: 0.95, green: 0.70, blue: 0.20)
    static let coral = Color(red: 0.95, green: 0.42, blue: 0.37)
    static let slate = Color(red: 0.28, green: 0.35, blue: 0.42)

    static func genreColor(_ genre: ProgressionGenre) -> Color {
        switch genre {
        case .pop: return teal
        case .rock: return coral
        case .folk: return Color(red: 0.45, green: 0.72, blue: 0.36)
        case .jazz: return Color(red: 0.58, green: 0.40, blue: 0.82)
        case .blues: return Color(red: 0.25, green: 0.50, blue: 0.78)
        case .country: return amber
        case .rnb: return Color(red: 0.85, green: 0.35, blue: 0.60)
        case .other: return slate
        }
    }

    static func qualityColor(_ quality: ChordQuality) -> Color {
        switch quality {
        case .major: return teal
        case .minor: return Color(red: 0.45, green: 0.35, blue: 0.72)
        case .dominant7, .major7, .minor7: return amber
        case .diminished: return coral
        case .augmented: return Color(red: 0.85, green: 0.45, blue: 0.20)
        case .sus2, .sus4: return Color(red: 0.30, green: 0.65, blue: 0.45)
        case .add9: return Color(red: 0.20, green: 0.55, blue: 0.80)
        case .power: return slate
        }
    }
}

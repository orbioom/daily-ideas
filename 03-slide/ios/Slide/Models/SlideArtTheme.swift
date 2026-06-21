import SwiftUI

enum SlideArtTheme: String, CaseIterable, Identifiable {
    case classic, mountain, ocean, galaxy, forest
    var id: String { rawValue }
    var name: String {
        switch self {
        case .classic: return "Classic"
        case .mountain: return "Mountain"
        case .ocean: return "Ocean"
        case .galaxy: return "Galaxy"
        case .forest: return "Forest"
        }
    }
    var isPro: Bool { self == .galaxy || self == .forest }
    var accent: Color {
        switch self {
        case .classic: return SlideTheme.accent
        case .mountain: return Color(red: 0.90, green: 0.60, blue: 0.30)
        case .ocean: return Color(red: 0.30, green: 0.70, blue: 0.95)
        case .galaxy: return Color(red: 0.70, green: 0.40, blue: 0.95)
        case .forest: return Color(red: 0.30, green: 0.70, blue: 0.40)
        }
    }

    func tileColor(tile: Int, total: Int) -> Color {
        let frac = Double(tile) / Double(max(total, 1))
        switch self {
        case .classic:
            return SlideTheme.tileBg.opacity(0.9 + 0.1 * frac)
        case .mountain:
            return Color(hue: 0.08 + 0.05 * frac, saturation: 0.5, brightness: 0.55 + 0.2 * frac)
        case .ocean:
            return Color(hue: 0.55 + 0.08 * frac, saturation: 0.6 + 0.2 * frac, brightness: 0.5 + 0.2 * frac)
        case .galaxy:
            return Color(hue: 0.70 + 0.15 * frac, saturation: 0.5, brightness: 0.35 + 0.25 * frac)
        case .forest:
            return Color(hue: 0.28 + 0.10 * frac, saturation: 0.5 + 0.2 * frac, brightness: 0.35 + 0.20 * frac)
        }
    }
}

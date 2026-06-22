import SwiftUI

enum CrescentTheme {
    static let navy    = Color(red: 0.051, green: 0.059, blue: 0.118)
    static let silver  = Color(red: 0.753, green: 0.753, blue: 0.800)
    static let pearl   = Color(red: 0.961, green: 0.941, blue: 0.910)
    static let gold    = Color(red: 0.784, green: 0.663, blue: 0.431)
    static let dark    = Color(red: 0.031, green: 0.035, blue: 0.071)
    static let cardBg  = Color(red: 0.082, green: 0.094, blue: 0.176)

    static func phaseColor(_ phase: MoonPhase) -> Color {
        switch phase {
        case .newMoon:        return Color(white: 0.2)
        case .waxingCrescent: return Color(red: 0.4, green: 0.5, blue: 0.7)
        case .firstQuarter:   return Color(red: 0.5, green: 0.6, blue: 0.8)
        case .waxingGibbous:  return Color(red: 0.7, green: 0.8, blue: 0.9)
        case .fullMoon:       return pearl
        case .waningGibbous:  return Color(red: 0.8, green: 0.8, blue: 0.7)
        case .lastQuarter:    return Color(red: 0.6, green: 0.6, blue: 0.5)
        case .waningCrescent: return Color(red: 0.4, green: 0.4, blue: 0.35)
        }
    }
}

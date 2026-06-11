import SwiftUI

enum Theme {
    static let accent = Color("AccentColor")
    static let bgPrimary = Color("BGPrimary")
    static let bgSecondary = Color("BGSecondary")
    static let textPrimary = Color("TextPrimary")

    static let gold = Color(red: 0.98, green: 0.76, blue: 0.32)
    static let silver = Color(red: 0.78, green: 0.81, blue: 0.88)

    static func statusColor(_ status: WatchStatus) -> Color {
        switch status {
        case .watchlist: return .blue
        case .watching:  return Theme.gold
        case .watched:   return Color(red: 0.37, green: 0.87, blue: 0.54)
        }
    }

    static func genreColor(_ genre: MediaGenre) -> Color {
        switch genre {
        case .action:      return Color(red: 0.95, green: 0.37, blue: 0.32)
        case .comedy:      return Color(red: 0.98, green: 0.76, blue: 0.32)
        case .drama:       return Color(red: 0.54, green: 0.69, blue: 0.95)
        case .thriller:    return Color(red: 0.65, green: 0.40, blue: 0.90)
        case .horror:      return Color(red: 0.80, green: 0.22, blue: 0.22)
        case .sciFi:       return Color(red: 0.32, green: 0.88, blue: 0.98)
        case .fantasy:     return Color(red: 0.90, green: 0.55, blue: 0.90)
        case .romance:     return Color(red: 0.98, green: 0.53, blue: 0.69)
        case .documentary: return Color(red: 0.60, green: 0.80, blue: 0.60)
        case .animation:   return Color(red: 0.98, green: 0.65, blue: 0.33)
        case .crime:       return Color(red: 0.72, green: 0.72, blue: 0.72)
        case .adventure:   return Color(red: 0.40, green: 0.78, blue: 0.58)
        case .other:       return Theme.silver
        }
    }
}

import SwiftUI

enum SkimTheme {
    enum ReaderBackground: String, CaseIterable, Codable {
        case white  = "White"
        case cream  = "Cream"
        case dark   = "Dark"
        case night  = "Night"

        var background: Color {
            switch self {
            case .white: return .white
            case .cream: return Color(red: 0.98, green: 0.96, blue: 0.88)
            case .dark:  return Color(red: 0.15, green: 0.15, blue: 0.18)
            case .night: return Color(red: 0.04, green: 0.04, blue: 0.06)
            }
        }

        var text: Color {
            switch self {
            case .white, .cream: return Color(red: 0.1, green: 0.1, blue: 0.15)
            case .dark, .night:  return .white
            }
        }

        var isDark: Bool {
            self == .dark || self == .night
        }
    }

    static let accent = Color(red: 0.10, green: 0.55, blue: 0.96)
    static let focusLine = Color(red: 0.10, green: 0.55, blue: 0.96).opacity(0.15)
}

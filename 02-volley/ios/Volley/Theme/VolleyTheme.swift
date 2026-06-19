import SwiftUI

struct VolleyTheme {
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let accent = Color(hex: "F97316")

    static func gradient(for mode: QuestionMode) -> [Color] {
        switch mode {
        case .wouldYouRather:  return [Color(hex: "F97316"), Color(hex: "DC2626")]
        case .truthOrDare:     return [Color(hex: "7C3AED"), Color(hex: "4F46E5")]
        case .neverHaveIEver:  return [Color(hex: "0891B2"), Color(hex: "0D9488")]
        case .icebreaker:      return [Color(hex: "059669"), Color(hex: "16A34A")]
        }
    }

    static func icon(for mode: QuestionMode) -> String {
        switch mode {
        case .wouldYouRather:  return "arrow.left.arrow.right"
        case .truthOrDare:     return "flame.fill"
        case .neverHaveIEver:  return "hand.raised.fill"
        case .icebreaker:      return "sparkles"
        }
    }

    static func primaryColor(for mode: QuestionMode) -> Color {
        gradient(for: mode).first ?? accent
    }

    static func categoryColor(for category: QuestionCategory) -> Color {
        switch category {
        case .all:     return .gray
        case .family:  return Color(hex: "059669")
        case .friends: return Color(hex: "2563EB")
        case .couples: return Color(hex: "DB2777")
        case .party:   return Color(hex: "D97706")
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

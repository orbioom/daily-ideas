import SwiftUI

enum FlowTheme {
    static let accent = Color("AccentColor")
    static let bg = Color("BGPrimary")
    static let card = Color("BGSecondary")
    static let text = Color("TextPrimary")
    static let subtle = Color.secondary

    static let sage = Color(red: 0.47, green: 0.65, blue: 0.52)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let warm = Color(red: 0.92, green: 0.78, blue: 0.62)

    static func colorFromHex(_ hex: String) -> Color {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return .green }
        return Color(red: Double((val >> 16) & 0xFF) / 255,
                     green: Double((val >> 8) & 0xFF) / 255,
                     blue: Double(val & 0xFF) / 255)
    }

    static func gradient(for session: YogaSession) -> LinearGradient {
        let c1 = colorFromHex(session.gradientColors[0])
        let c2 = colorFromHex(session.gradientColors[1])
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1: return .red.opacity(0.8)
        case 2: return .orange.opacity(0.8)
        case 3: return .yellow.opacity(0.8)
        case 4: return sage
        case 5: return .green
        default: return .gray
        }
    }

    static func moodEmoji(_ mood: Int) -> String {
        ["", "😔", "😕", "😐", "🙂", "😊"][min(5, max(0, mood))]
    }
}

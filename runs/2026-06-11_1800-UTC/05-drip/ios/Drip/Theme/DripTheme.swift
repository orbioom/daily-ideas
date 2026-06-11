import SwiftUI

enum DripTheme {
    static let accent = Color("AccentColor")
    static let bg = Color("BGPrimary")
    static let card = Color("BGSecondary")
    static let text = Color("TextPrimary")
    static let subtle = Color.secondary

    static let teal = Color(red: 0.22, green: 0.68, blue: 0.70)
    static let soft = Color(red: 0.22, green: 0.68, blue: 0.70).opacity(0.15)
    static let warning = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let danger = Color(red: 0.92, green: 0.35, blue: 0.35)
    static let safe = Color(red: 0.30, green: 0.80, blue: 0.55)

    static func statusColor(drinks: Double, limit: Int) -> Color {
        let pct = drinks / Double(max(1, limit))
        if pct < 0.6 { return safe }
        if pct < 0.9 { return warning }
        return danger
    }
}

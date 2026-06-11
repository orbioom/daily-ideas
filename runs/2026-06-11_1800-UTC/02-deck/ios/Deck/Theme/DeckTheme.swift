import SwiftUI

enum DeckTheme {
    static let accent = Color("AccentColor")
    static let bg = Color("BGPrimary")
    static let card = Color("BGSecondary")
    static let text = Color("TextPrimary")
    static let subtle = Color.secondary

    static let deckColors: [(name: String, hex: String)] = [
        ("Blue",   "#4F8EF7"),
        ("Purple", "#9B6BFF"),
        ("Pink",   "#F76FA0"),
        ("Orange", "#F79A4F"),
        ("Teal",   "#4FC8C8"),
        ("Green",  "#5ECC7B"),
        ("Red",    "#F75454"),
        ("Gray",   "#8C8FA0")
    ]

    static func colorFromHex(_ hex: String) -> Color {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return .blue }
        return Color(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255
        )
    }

    static func ratingColor(_ rating: ReviewRating) -> Color {
        switch rating {
        case .again: return .red
        case .hard:  return .orange
        case .good:  return .green
        case .easy:  return .blue
        }
    }
}

import SwiftUI

struct KeysTheme {
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let accent = Color(red: 0.176, green: 0.478, blue: 0.310)
    static let accentLight = Color(red: 0.220, green: 0.580, blue: 0.380)
    static let keyWhite = Color(.white)
    static let keyBlack = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let separator = Color(.separator)

    // Piano aesthetic: deep charcoal for dark contexts
    static let pianoBackground = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let pianoSurface = Color(red: 0.15, green: 0.15, blue: 0.18)
}

extension Color {
    static let keysAccent = KeysTheme.accent
}

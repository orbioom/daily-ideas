import SwiftUI

enum AmpTheme {
    static let blue = Color("AmpBlue")
    static let navy = Color("AmpNavy")
    static let green = Color("AmpGreen")
    static let accent = Color.accentColor

    static func gradient(_ colors: [Color] = [Color("AmpBlue"), Color("AmpNavy")]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let cardBackground = Color(.secondarySystemBackground)
}

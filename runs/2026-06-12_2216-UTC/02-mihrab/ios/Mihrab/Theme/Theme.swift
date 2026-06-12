import SwiftUI

/// Mihrab design language: a night sky over a courtyard — deep indigo,
/// warm brass-gold, generous serif headings, soft star accents.
enum MihrabTheme {
    static let gold = Color(red: 0.79, green: 0.66, blue: 0.30)
    static let indigoDeep = Color(red: 0.07, green: 0.09, blue: 0.22)
    static let indigoSoft = Color(red: 0.12, green: 0.15, blue: 0.33)

    static func skyGradient(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.16), Color(red: 0.02, green: 0.03, blue: 0.09)],
                startPoint: .top, endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.10, green: 0.13, blue: 0.30), Color(red: 0.06, green: 0.08, blue: 0.20)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

extension View {
    func mihrabPanel() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

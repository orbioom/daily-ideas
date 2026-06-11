import SwiftUI

/// Lectern's design language: "broadcast studio" — warm amber on deep
/// charcoal in dark mode, warm paper neutrals in light mode. Serif display
/// type for script content, rounded sans for chrome.
enum Theme {
    static let accent = Color(red: 1.0, green: 0.706, blue: 0.329)        // amber

    static let bgPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.082, green: 0.086, blue: 0.106, alpha: 1)
            : UIColor(red: 0.972, green: 0.965, blue: 0.949, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.125, green: 0.129, blue: 0.157, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.925, green: 0.933, blue: 0.953, alpha: 1)
            : UIColor(red: 0.118, green: 0.122, blue: 0.145, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.64, blue: 0.70, alpha: 1)
            : UIColor(red: 0.42, green: 0.43, blue: 0.47, alpha: 1)
    })
    /// The prompter stage itself is always near-black, in both modes —
    /// like real teleprompter glass.
    static let stage = Color(red: 0.04, green: 0.045, blue: 0.06)

    static func cardStyle() -> some ViewModifier { CardModifier() }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func lecternCard() -> some View { modifier(CardModifier()) }
}

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

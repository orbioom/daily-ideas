import SwiftUI

/// Reverie's design language: "moonlit" — soft periwinkle and indigo on a deep
/// midnight blue. Serif for dream narratives (dreamlike, literary), rounded
/// sans for chrome. Calm, nocturnal, private.
enum Theme {
    static let accent = Color(red: 0.475, green: 0.522, blue: 0.835)   // indigo periwinkle

    static let bgPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.047, green: 0.055, blue: 0.118, alpha: 1)
            : UIColor(red: 0.961, green: 0.965, blue: 0.984, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.090, green: 0.102, blue: 0.180, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.929, green: 0.937, blue: 0.973, alpha: 1)
            : UIColor(red: 0.094, green: 0.102, blue: 0.180, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.620, green: 0.643, blue: 0.745, alpha: 1)
            : UIColor(red: 0.404, green: 0.424, blue: 0.522, alpha: 1)
    })
    static let track = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.157, green: 0.176, blue: 0.275, alpha: 1)
            : UIColor(red: 0.894, green: 0.902, blue: 0.945, alpha: 1)
    })
    static let lucid = Color(red: 0.40, green: 0.78, blue: 0.78)        // teal — lucidity
    static let star = Color(red: 0.96, green: 0.86, blue: 0.55)

    static let nightSky = LinearGradient(
        colors: [Color(red: 0.114, green: 0.133, blue: 0.255), Color(red: 0.055, green: 0.063, blue: 0.149)],
        startPoint: .top, endPoint: .bottom)
    static let moonGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.60, blue: 0.90), Color(red: 0.40, green: 0.45, blue: 0.78)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
extension View {
    func reverieCard() -> some View { modifier(CardModifier()) }
}

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
            ? true : UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

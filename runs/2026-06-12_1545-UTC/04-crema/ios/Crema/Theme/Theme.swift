import SwiftUI

/// Crema's design language: "warm roast" — caramel and copper on a deep
/// espresso brown in dark mode, warm cream in light mode. Rounded, tactile,
/// a little café-menu warmth. Crema-gold is the signal colour.
enum Theme {
    static let accent = Color(red: 0.753, green: 0.506, blue: 0.306)   // caramel/copper

    static let bgPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.094, green: 0.063, blue: 0.043, alpha: 1)
            : UIColor(red: 0.980, green: 0.965, blue: 0.945, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.149, green: 0.106, blue: 0.075, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.961, green: 0.937, blue: 0.910, alpha: 1)
            : UIColor(red: 0.180, green: 0.118, blue: 0.078, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.706, green: 0.643, blue: 0.588, alpha: 1)
            : UIColor(red: 0.451, green: 0.388, blue: 0.337, alpha: 1)
    })
    static let track = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.243, green: 0.180, blue: 0.137, alpha: 1)
            : UIColor(red: 0.918, green: 0.890, blue: 0.851, alpha: 1)
    })
    static let crema = Color(red: 0.85, green: 0.62, blue: 0.33)
    static let sour = Color(red: 0.84, green: 0.71, blue: 0.22)
    static let bitter = Color(red: 0.55, green: 0.33, blue: 0.28)
    static let balanced = Color(red: 0.36, green: 0.62, blue: 0.42)

    static let cremaGradient = LinearGradient(
        colors: [Color(red: 0.87, green: 0.64, blue: 0.36), Color(red: 0.69, green: 0.45, blue: 0.24)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
extension View {
    func cremaCard() -> some View { modifier(CardModifier()) }
}

enum Haptics {
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") == nil
            ? true : UserDefaults.standard.bool(forKey: "hapticsEnabled")
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

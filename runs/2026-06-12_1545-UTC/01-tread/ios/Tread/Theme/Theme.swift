import SwiftUI

/// Tread's design language: "fresh trail" — vivid emerald on a deep forest
/// charcoal in dark mode, airy mist white in light mode. Rounded, friendly,
/// motion-forward. The progress ring is the hero of every screen.
enum Theme {
    static let accent = Color(red: 0.133, green: 0.710, blue: 0.451)   // emerald

    static let bgPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.043, green: 0.094, blue: 0.078, alpha: 1)
            : UIColor(red: 0.957, green: 0.976, blue: 0.965, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.075, green: 0.137, blue: 0.118, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.925, green: 0.953, blue: 0.941, alpha: 1)
            : UIColor(red: 0.063, green: 0.122, blue: 0.102, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.604, green: 0.682, blue: 0.651, alpha: 1)
            : UIColor(red: 0.357, green: 0.435, blue: 0.404, alpha: 1)
    })
    static let track = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.149, green: 0.231, blue: 0.204, alpha: 1)
            : UIColor(red: 0.875, green: 0.925, blue: 0.902, alpha: 1)
    })
    static let warm = Color(red: 0.98, green: 0.70, blue: 0.32)         // sunrise gold

    static let ringGradient = LinearGradient(
        colors: [Color(red: 0.18, green: 0.78, blue: 0.49), Color(red: 0.09, green: 0.62, blue: 0.55)],
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
    func treadCard() -> some View { modifier(CardModifier()) }
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

import SwiftUI

/// Checkpoint's design language: "arcade dusk" — electric violet on a deep
/// indigo night. Rounded display type, glowing status pills, a playful but
/// legible collection feel.
enum Theme {
    static let accent = Color(red: 0.694, green: 0.361, blue: 0.941)   // electric violet

    static let bgPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.055, blue: 0.125, alpha: 1)
            : UIColor(red: 0.965, green: 0.961, blue: 0.984, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.118, green: 0.094, blue: 0.196, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.945, green: 0.937, blue: 0.973, alpha: 1)
            : UIColor(red: 0.110, green: 0.086, blue: 0.165, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.659, green: 0.631, blue: 0.745, alpha: 1)
            : UIColor(red: 0.435, green: 0.408, blue: 0.522, alpha: 1)
    })
    static let track = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.176, green: 0.149, blue: 0.275, alpha: 1)
            : UIColor(red: 0.902, green: 0.890, blue: 0.945, alpha: 1)
    })
    static let gold = Color(red: 0.98, green: 0.76, blue: 0.30)

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.30, blue: 0.95), Color(red: 0.36, green: 0.22, blue: 0.78)],
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
    func cpCard() -> some View { modifier(CardModifier()) }
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

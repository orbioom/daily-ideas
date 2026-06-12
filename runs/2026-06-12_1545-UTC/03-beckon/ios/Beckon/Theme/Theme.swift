import SwiftUI

/// Beckon's design language: "cosmic gold" — warm gold leaf on a deep plum
/// night sky. Serif display for affirmations (intimate, ceremonial), rounded
/// sans for chrome. Soft glows, gentle breathing motion.
enum Theme {
    static let accent = Color(red: 0.851, green: 0.643, blue: 0.255)   // gold

    static let bgPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.055, blue: 0.118, alpha: 1)
            : UIColor(red: 0.984, green: 0.973, blue: 0.953, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.137, green: 0.106, blue: 0.196, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.961, green: 0.945, blue: 0.910, alpha: 1)
            : UIColor(red: 0.157, green: 0.118, blue: 0.094, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.706, green: 0.667, blue: 0.745, alpha: 1)
            : UIColor(red: 0.435, green: 0.388, blue: 0.392, alpha: 1)
    })
    static let track = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.220, green: 0.180, blue: 0.290, alpha: 1)
            : UIColor(red: 0.929, green: 0.910, blue: 0.875, alpha: 1)
    })
    static let nightSky = LinearGradient(
        colors: [Color(red: 0.118, green: 0.086, blue: 0.196), Color(red: 0.063, green: 0.047, blue: 0.110)],
        startPoint: .top, endPoint: .bottom)
    static let goldGradient = LinearGradient(
        colors: [Color(red: 0.93, green: 0.74, blue: 0.36), Color(red: 0.80, green: 0.58, blue: 0.22)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
extension View {
    func beckonCard() -> some View { modifier(CardModifier()) }
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
    static func rep() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

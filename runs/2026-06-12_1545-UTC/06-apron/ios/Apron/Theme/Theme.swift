import SwiftUI

/// Apron's design language: "after the shift" — fresh teal-green (the color of
/// cash and calm) on a warm charcoal in dark mode, clean off-white in light.
/// Big confident numbers; this app is about seeing your real take-home clearly.
enum Theme {
    static let accent = Color(red: 0.059, green: 0.663, blue: 0.561)   // teal-green

    static let bgPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.043, green: 0.078, blue: 0.071, alpha: 1)
            : UIColor(red: 0.957, green: 0.973, blue: 0.969, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.122, blue: 0.110, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.925, green: 0.957, blue: 0.945, alpha: 1)
            : UIColor(red: 0.051, green: 0.110, blue: 0.094, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.588, green: 0.667, blue: 0.643, alpha: 1)
            : UIColor(red: 0.341, green: 0.435, blue: 0.408, alpha: 1)
    })
    static let track = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.137, green: 0.212, blue: 0.192, alpha: 1)
            : UIColor(red: 0.871, green: 0.918, blue: 0.902, alpha: 1)
    })
    static let cash = Color(red: 0.36, green: 0.74, blue: 0.49)
    static let card = Color(red: 0.30, green: 0.62, blue: 0.85)
    static let wage = Color(red: 0.86, green: 0.66, blue: 0.30)

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.72, blue: 0.60), Color(red: 0.05, green: 0.55, blue: 0.50)],
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
    func apronCard() -> some View { modifier(CardModifier()) }
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

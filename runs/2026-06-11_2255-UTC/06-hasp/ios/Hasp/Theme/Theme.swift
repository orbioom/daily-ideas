import SwiftUI

/// Hasp's design language: "bank vault at midnight" — violet on near-black,
/// brushed-steel neutrals, monospaced secrets. Light mode is cool porcelain.
enum Theme {
    static let accent = Color(red: 0.616, green: 0.549, blue: 1.0)   // vault violet
    static let danger = Color(red: 1.0, green: 0.45, blue: 0.45)
    static let ok = Color(red: 0.37, green: 0.94, blue: 0.69)

    static let bgPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.067, green: 0.063, blue: 0.094, alpha: 1)
            : UIColor(red: 0.949, green: 0.945, blue: 0.965, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.118, green: 0.110, blue: 0.157, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.929, green: 0.922, blue: 0.953, alpha: 1)
            : UIColor(red: 0.125, green: 0.114, blue: 0.169, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.60, blue: 0.69, alpha: 1)
            : UIColor(red: 0.42, green: 0.40, blue: 0.48, alpha: 1)
    })
}

extension View {
    func haspCard() -> some View {
        padding(16)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
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
    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

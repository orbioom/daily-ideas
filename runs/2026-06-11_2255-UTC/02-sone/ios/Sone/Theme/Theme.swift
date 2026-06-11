import SwiftUI

/// Sone's design language: "precision instrument" — cool cyan on graphite,
/// monospaced numerals, thin hairline gauges. Light mode is a pale lab grey.
enum Theme {
    static let accent = Color(red: 0.369, green: 0.827, blue: 0.941)   // instrument cyan

    static let safe = Color(red: 0.369, green: 0.941, blue: 0.690)
    static let caution = Color(red: 1.0, green: 0.804, blue: 0.431)
    static let danger = Color(red: 1.0, green: 0.463, blue: 0.463)

    static let bgPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.078, blue: 0.094, alpha: 1)
            : UIColor(red: 0.949, green: 0.957, blue: 0.965, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.114, green: 0.125, blue: 0.149, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.918, green: 0.933, blue: 0.949, alpha: 1)
            : UIColor(red: 0.110, green: 0.125, blue: 0.149, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.63, blue: 0.68, alpha: 1)
            : UIColor(red: 0.40, green: 0.43, blue: 0.47, alpha: 1)
    })

    static func levelColor(_ db: Double) -> Color {
        switch db {
        case ..<70: return safe
        case ..<85: return caution
        default: return danger
        }
    }
}

extension View {
    func soneCard() -> some View {
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
    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

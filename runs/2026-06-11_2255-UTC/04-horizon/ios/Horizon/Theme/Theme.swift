import SwiftUI

/// Horizon's design language: "first light" — deep evergreen and ivory with
/// a dawn-gold secondary, serif numerals for money. Calm, bank-grade.
enum Theme {
    static let accent = Color(red: 0.478, green: 0.863, blue: 0.608)   // evergreen mint
    static let gold = Color(red: 1.0, green: 0.804, blue: 0.431)

    static let bgPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.063, green: 0.086, blue: 0.078, alpha: 1)
            : UIColor(red: 0.953, green: 0.961, blue: 0.949, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.102, green: 0.137, blue: 0.122, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.918, green: 0.941, blue: 0.925, alpha: 1)
            : UIColor(red: 0.090, green: 0.137, blue: 0.114, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.64, blue: 0.60, alpha: 1)
            : UIColor(red: 0.36, green: 0.43, blue: 0.39, alpha: 1)
    })
}

extension View {
    func horizonCard() -> some View {
        padding(16)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
}

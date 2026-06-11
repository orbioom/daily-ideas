import SwiftUI

/// Romp's design language: "confetti arcade" — punchy coral on cream,
/// chunky rounded type, candy-colored deck cards. Dark mode goes plum.
enum Theme {
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.506)      // coral
    static let correct = Color(red: 0.29, green: 0.87, blue: 0.6)
    static let pass = Color(red: 1.0, green: 0.78, blue: 0.35)

    static let bgPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.118, green: 0.078, blue: 0.118, alpha: 1)
            : UIColor(red: 0.992, green: 0.965, blue: 0.941, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.122, blue: 0.173, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.965, green: 0.929, blue: 0.949, alpha: 1)
            : UIColor(red: 0.196, green: 0.118, blue: 0.157, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.69, green: 0.61, blue: 0.66, alpha: 1)
            : UIColor(red: 0.48, green: 0.40, blue: 0.45, alpha: 1)
    })

    /// Candy palette for deck cards.
    static let deckColors: [Color] = [
        Color(red: 1.0, green: 0.42, blue: 0.506),
        Color(red: 0.38, green: 0.62, blue: 1.0),
        Color(red: 0.29, green: 0.78, blue: 0.6),
        Color(red: 1.0, green: 0.69, blue: 0.30),
        Color(red: 0.69, green: 0.52, blue: 1.0),
        Color(red: 0.95, green: 0.55, blue: 0.85),
        Color(red: 0.35, green: 0.80, blue: 0.85),
        Color(red: 0.92, green: 0.60, blue: 0.45),
    ]
}

extension View {
    func rompCard() -> some View {
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
    static func correct() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func pass() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

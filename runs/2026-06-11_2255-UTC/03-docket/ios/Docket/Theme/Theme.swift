import SwiftUI

/// Docket's design language: "paper & ink ledger" — crisp white/ivory cards,
/// archival blue accent, tight grids. Dark mode is slate with the same blue.
enum Theme {
    static let accent = Color(red: 0.357, green: 0.549, blue: 1.0)   // archival blue

    static let bgPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.075, green: 0.082, blue: 0.102, alpha: 1)
            : UIColor(red: 0.945, green: 0.949, blue: 0.961, alpha: 1)
    })
    static let bgElevated = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.122, green: 0.133, blue: 0.161, alpha: 1)
            : UIColor.white
    })
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.918, green: 0.929, blue: 0.949, alpha: 1)
            : UIColor(red: 0.110, green: 0.122, blue: 0.153, alpha: 1)
    })
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.62, blue: 0.67, alpha: 1)
            : UIColor(red: 0.40, green: 0.42, blue: 0.47, alpha: 1)
    })
}

extension View {
    func docketCard() -> some View {
        padding(16)
            .background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

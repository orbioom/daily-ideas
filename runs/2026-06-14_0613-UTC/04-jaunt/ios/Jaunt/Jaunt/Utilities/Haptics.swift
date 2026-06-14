import UIKit

/// Lightweight haptic helper. All calls are gated by the user's preference,
/// which is read fresh from UserDefaults so the engine stays decoupled from views.
enum Haptics {

    private static var enabled: Bool {
        // Default to true when the key has never been written.
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }

    static func tap() {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func select() {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
    }

    static func success() {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }
}

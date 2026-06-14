import UIKit

/// Lightweight haptics, gated by the user's settings toggle. Sparse by design:
/// used for place, line-clear, and game-over only.
enum Haptics {
    static func place(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func select(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
    }

    static func clear(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func gameOver(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }

    static func invalid(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.impactOccurred(intensity: 0.6)
    }
}

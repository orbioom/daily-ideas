import UIKit

/// Sparse, meaningful haptics. All calls are gated by the caller on the Settings toggle.
enum Haptics {
    /// A light tap for placing a card.
    static func light(enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// A medium tap for a notable move (auto-collect, supermove).
    static func medium(enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// A success notification for winning a game.
    static func success(enabled: Bool) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// A soft warning for an invalid action.
    static func warning(enabled: Bool) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

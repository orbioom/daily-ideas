import UIKit

/// Small haptics helper. Every call is gated by the caller via `settings.hapticsEnabled`.
@MainActor
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func soft(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    static func celebrate(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.impactOccurred()
    }
}

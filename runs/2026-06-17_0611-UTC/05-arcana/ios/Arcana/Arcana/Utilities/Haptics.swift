import UIKit

/// Sparse, intentional haptics. Every call is gated by the user's `hapticsEnabled` preference.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    static func reveal(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }
}

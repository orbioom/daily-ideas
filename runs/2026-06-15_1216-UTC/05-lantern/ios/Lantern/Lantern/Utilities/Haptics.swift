import UIKit

/// Sparse, gated haptics. Each call is a no-op when `enabled` is false.
enum Haptics {
    static func select(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    static func match(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }
    static func win(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    static func warn(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }
}

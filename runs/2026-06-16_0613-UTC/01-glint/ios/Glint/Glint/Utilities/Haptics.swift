import UIKit

/// Small haptics helper. All calls are gated by the caller on `settings.hapticsEnabled`.
enum Haptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func match() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }

    static func cascade(intensity: CGFloat) {
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.impactOccurred(intensity: min(1.0, max(0.4, intensity)))
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }
}

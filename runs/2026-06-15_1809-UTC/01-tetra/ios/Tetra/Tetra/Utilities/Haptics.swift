import UIKit

/// Sparse, gated haptic feedback. Pass the current setting so taps stay quiet when disabled.
enum Haptics {
    static func tap(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func rigid(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.impactOccurred()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
}

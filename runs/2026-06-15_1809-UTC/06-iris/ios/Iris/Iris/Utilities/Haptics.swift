import UIKit

/// Sparse, gated haptic feedback. Pass the current setting so taps stay quiet when disabled.
enum Haptics {
    static func tap(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
}

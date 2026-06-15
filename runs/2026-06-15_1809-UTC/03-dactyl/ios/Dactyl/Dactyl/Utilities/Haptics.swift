import UIKit

/// Sparse, gated haptic feedback. Pass the current setting so taps stay quiet when disabled.
enum Haptics {
    static func tap(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    /// A slightly sharper tap used to flag a typing error.
    static func error(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.impactOccurred(intensity: 0.7)
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

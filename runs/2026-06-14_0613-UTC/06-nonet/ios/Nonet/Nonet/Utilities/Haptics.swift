import UIKit

/// Sparse, settings-gated haptic feedback for placing, errors, and wins.
enum Haptics {
    static func place(enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    static func error(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.error)
    }

    static func win(enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }
}

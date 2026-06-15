import UIKit

/// Lightweight haptics, always gated by the user's settings toggle. Sparse by design: a tick
/// when a value is logged, a soft success when a day is fully saved, a selection tick on
/// navigation, and a warning for destructive confirmations.
enum Haptics {
    static func log(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func select(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.selectionChanged()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func warning(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }
}

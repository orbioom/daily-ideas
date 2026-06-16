import UIKit

/// Small haptics helper. All calls are gated by the caller passing the current
/// `hapticsEnabled` preference so feedback never fires when disabled.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func selection(_ enabled: Bool) {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
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

    static func error(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }
}

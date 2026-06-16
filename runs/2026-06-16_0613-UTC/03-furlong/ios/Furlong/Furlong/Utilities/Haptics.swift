import UIKit

/// Small haptics helper. Every call is gated by the caller passing the
/// current `enabled` flag from AppSettings, so users can silence feedback.
enum Haptics {
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

    static func impact(_ enabled: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
    }

    static func selection(_ enabled: Bool) {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }
}

import UIKit

/// Small haptics helper, gated by AppSettings.hapticsEnabled at the call site.
enum Haptics {
    static func selection(_ enabled: Bool) {
        guard enabled else { return }
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }

    static func impact(_ enabled: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    static func warning(_ enabled: Bool) {
        guard enabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }
}

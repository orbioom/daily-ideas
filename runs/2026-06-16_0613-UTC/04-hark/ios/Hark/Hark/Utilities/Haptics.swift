import UIKit

/// Small wrapper around UIKit feedback generators. Every call is gated by the caller
/// passing `enabled` (driven by settings.hapticsEnabled).
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

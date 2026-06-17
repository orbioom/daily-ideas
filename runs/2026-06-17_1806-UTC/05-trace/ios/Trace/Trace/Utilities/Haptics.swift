import UIKit

/// Lightweight haptics helper. All calls are no-ops unless `enabled` is true,
/// so callers can pass `settings.hapticsEnabled` at the call site.
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.warning)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }
}

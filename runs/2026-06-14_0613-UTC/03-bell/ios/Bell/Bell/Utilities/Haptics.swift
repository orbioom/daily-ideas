import UIKit

/// Sparse, taste-respecting haptics. All calls gated by the settings toggle
/// passed in, so callers must opt in explicitly.
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .soft, enabled: Bool) {
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

    /// A soft double-tap used as a silent bell cue when audio is unavailable.
    static func bellCue(enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.prepare()
        gen.impactOccurred(intensity: 0.7)
    }
}

import UIKit

/// Purposeful, sparse haptics — gated by the Settings toggle. Never noise.
enum Haptics {
    static func success(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func impact(enabled: Bool, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// A pre-prepared generator for the metronome beat — preparing avoids latency on
    /// the first tick. Reused across beats so feedback stays crisp and in time.
    static func makeBeatGenerator() -> UIImpactFeedbackGenerator {
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.prepare()
        return gen
    }
}

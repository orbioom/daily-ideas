import UIKit

/// Sparse haptic feedback, gated by a Settings toggle so it's never noisy.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func beat(_ enabled: Bool, accent: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: accent ? .medium : .light)
        gen.impactOccurred(intensity: accent ? 1.0 : 0.6)
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}

extension Collection {
    /// Safe indexing — returns nil instead of trapping on an out-of-range index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

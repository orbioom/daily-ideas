import UIKit

/// Sparse haptic feedback, gated by the Settings toggle.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
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

extension Collection {
    /// Safe indexing — returns nil instead of trapping on an out-of-range index.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

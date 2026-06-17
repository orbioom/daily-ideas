import UIKit

/// Sparse haptic feedback, gated by the Settings toggle.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func medium(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    static func heavy(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .rigid)
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

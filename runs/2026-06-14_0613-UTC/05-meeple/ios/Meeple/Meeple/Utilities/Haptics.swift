import UIKit

/// Lightweight, settings-gated haptics. Call sites pass `enabled` from AppSettings.
enum Haptics {
    static func tap(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    static func success(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
    }

    static func warning(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.warning)
    }

    static func selection(_ enabled: Bool) {
        guard enabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }
}

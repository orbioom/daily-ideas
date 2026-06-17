import UIKit

/// Thin, sparse haptics wrapper. All calls are gated by the user's Settings toggle,
/// which the caller passes in so this stays free of @AppStorage coupling.
enum Haptics {

    static func success(enabled: Bool) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func error(enabled: Bool) {
        guard enabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func light(enabled: Bool) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

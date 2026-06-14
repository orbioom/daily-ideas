import UIKit

/// Sparse, purposeful haptics. All calls are gated by the caller against the
/// Settings "haptics" toggle so the user is always in control.
enum Haptics {
    static func tap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func flag() {
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.impactOccurred()
    }

    static func win() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    static func lose() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.error)
    }
}

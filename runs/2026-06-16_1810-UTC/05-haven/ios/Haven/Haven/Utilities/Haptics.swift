import UIKit

/// Gentle, optional haptics used as breathing-phase cues. Always guarded by the
/// user's Settings toggle at the call site.
enum Haptics {

    /// A soft tap for a phase change (inhale/exhale boundary).
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.6)
    }

    /// A slightly firmer cue for a "hold" boundary.
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.5)
    }

    /// A warm success notification (e.g. finishing grounding).
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// A subtle selection tick.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

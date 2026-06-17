import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Sparse, intentional haptics, all gated by the Settings "haptics" toggle.
enum Haptics {

    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    /// A light tick when a pipe snaps into a new cell.
    static func tick() {
        #if canImport(UIKit)
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred(intensity: 0.5)
        #endif
    }

    /// A firmer tap when a color pair connects end-to-end.
    static func connect() {
        #if canImport(UIKit)
        guard enabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        #endif
    }

    /// A success notification when the whole puzzle is solved.
    static func solved() {
        #if canImport(UIKit)
        guard enabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        #endif
    }
}

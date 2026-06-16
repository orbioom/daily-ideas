import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Sparse haptic feedback, gated by a Settings toggle. All calls are no-ops on
/// platforms without UIKit feedback generators.
enum Haptics {
    static func success(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func light(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}

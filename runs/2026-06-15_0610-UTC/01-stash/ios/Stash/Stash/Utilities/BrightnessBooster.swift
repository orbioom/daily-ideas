import SwiftUI
import UIKit

/// A view modifier that pushes the screen to full brightness while the view is on
/// screen so checkout scanners can read the barcode, then restores the previous
/// brightness on disappear. Gated by a setting; respects Reduce Motion by snapping
/// rather than animating.
struct BrightnessBoost: ViewModifier {
    let active: Bool
    @State private var previousBrightness: CGFloat?

    func body(content: Content) -> some View {
        content
            .onAppear(perform: boost)
            .onDisappear(perform: restore)
    }

    private func boost() {
        guard active else { return }
        if previousBrightness == nil {
            previousBrightness = UIScreen.main.brightness
        }
        UIScreen.main.brightness = 1.0
    }

    private func restore() {
        if let previous = previousBrightness {
            UIScreen.main.brightness = previous
            previousBrightness = nil
        }
    }
}

extension View {
    /// Boost screen brightness to max while shown when `active` is true.
    func brightnessBoost(_ active: Bool) -> some View {
        modifier(BrightnessBoost(active: active))
    }
}

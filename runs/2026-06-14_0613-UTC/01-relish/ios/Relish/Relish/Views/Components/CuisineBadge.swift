import SwiftUI

/// Small circular cuisine icon tinted by its hue.
struct CuisineBadge: View {
    let cuisine: Cuisine
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: cuisine.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(cuisine.hue)
            .frame(width: size, height: size)
            .background(Circle().fill(cuisine.hue.opacity(0.15)))
            .accessibilityHidden(true)
    }
}

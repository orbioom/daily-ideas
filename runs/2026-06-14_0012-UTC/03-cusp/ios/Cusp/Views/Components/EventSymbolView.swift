import SwiftUI

/// Renders an event's symbol — an SF Symbol or an emoji — at a given size.
/// Decorative by default (the title carries the accessible meaning).
struct EventSymbolView: View {
    let symbol: String
    let isEmoji: Bool
    var size: CGFloat = 22
    var color: Color = .white

    var body: some View {
        Group {
            if isEmoji {
                Text(symbol)
                    .font(.system(size: size))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.9, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
        .accessibilityHidden(true)
    }
}

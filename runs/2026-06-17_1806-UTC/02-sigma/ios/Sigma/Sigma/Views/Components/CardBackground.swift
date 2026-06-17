import SwiftUI

/// A reusable rounded surface used to group content into a "card",
/// matching Sigma's calculator design language.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = Theme.cornerCard

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
    }
}

extension View {
    /// Wraps the view in a themed card surface.
    func card(padding: CGFloat = 18, cornerRadius: CGFloat = Theme.cornerCard) -> some View {
        modifier(CardBackground(padding: padding, cornerRadius: cornerRadius))
    }
}

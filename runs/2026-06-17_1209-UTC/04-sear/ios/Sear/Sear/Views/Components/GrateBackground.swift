import SwiftUI

/// A subtle grill-grate motif used behind big numerals. Decorative only.
struct GrateBackground: View {
    var spacing: CGFloat = 14
    var lineWidth: CGFloat = 2

    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var x: CGFloat = spacing
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            ctx.stroke(path, with: .color(Theme.ink.opacity(0.06)), lineWidth: lineWidth)
        }
        .accessibilityHidden(true)
    }
}

/// Standard rounded surface card.
struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }
}

extension View {
    func searCard(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

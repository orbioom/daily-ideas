import SwiftUI

/// A big, chunky, rounded button — the primary tappable target style.
struct ChunkyButton: View {
    let title: String
    var systemImage: String? = nil
    var style: Style = .primary
    var fullWidth: Bool = true
    let action: () -> Void

    enum Style { case primary, secondary, soft, danger }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .bold))
                }
                Text(title)
                    .font(Theme.rounded(20, .bold))
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: 30)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 2 : 0)
            )
            .scaleEffect(pressed && !reduceMotion ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var foreground: Color {
        switch style {
        case .primary, .danger: return .white
        case .secondary: return Theme.accentDeep
        case .soft: return Theme.ink
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary: Theme.heroGradient
        case .danger: Theme.bad
        case .secondary: Color.clear
        case .soft: Theme.surfaceAlt
        }
    }

    private var borderColor: Color {
        style == .secondary ? Theme.accent : .clear
    }
}

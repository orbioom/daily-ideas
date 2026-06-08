import SwiftUI

/// A large tappable button for home screen quick-actions.
/// Shows an SF symbol, label, and an optional "active" ring/glow when an
/// event of this kind is currently ongoing.
struct QuickActionButton: View {
    let kind: EventKind
    let isActive: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? kind.color.opacity(0.18) : Color.clear)
                        .frame(width: 60, height: 60)

                    if isActive && !reduceMotion {
                        Circle()
                            .stroke(kind.color.opacity(0.45), lineWidth: 2)
                            .frame(width: 60, height: 60)
                    }

                    Image(systemName: kind.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isActive ? kind.color : Brand.text)
                }

                Text(kind.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isActive ? kind.color.opacity(0.5) : Brand.glassStroke.opacity(0.45),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .shadow(color: Brand.cardShadow, radius: 8, x: 0, y: 4)
        .scaleEffect(1.0)
        .accessibilityLabel(isActive ? "Stop \(kind.label)" : "Start \(kind.label)")
        .accessibilityHint(isActive ? "Tap to stop the active \(kind.label) timer" : "Tap to log a \(kind.label)")
        .accessibilityAddTraits(.isButton)
    }
}

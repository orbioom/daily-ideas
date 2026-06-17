import SwiftUI

/// A tappable sound tile in the Mixer grid. Shows the sound's symbol, name, and
/// active/locked state with a soft glow when enabled (still in Reduce Motion).
struct SoundTile: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let type: SoundType
    let isEnabled: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? type.tint.opacity(0.22) : HushTheme.subtleSurface(scheme))
                        .frame(width: 56, height: 56)
                    Image(systemName: type.symbol)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isEnabled ? type.tint : HushTheme.secondaryText(scheme))
                    if isLocked {
                        ProBadge()
                            .offset(x: 22, y: -22)
                    }
                }
                Text(type.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HushTheme.primaryText(scheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(HushTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isEnabled ? type.tint.opacity(0.6) : HushTheme.hairline(scheme),
                                  lineWidth: isEnabled ? 1.5 : 1)
            )
            .shadow(color: (isEnabled && !reduceMotion) ? type.tint.opacity(0.35) : .clear,
                    radius: isEnabled ? 10 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(type.title)
        .accessibilityValue(isLocked ? "Locked, Pro feature" : (isEnabled ? "On" : "Off"))
        .accessibilityHint(isLocked ? "Unlock Hush Pro to use this sound." : type.blurb)
        .accessibilityAddTraits(isEnabled ? [.isButton, .isSelected] : .isButton)
    }
}

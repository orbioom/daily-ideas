import SwiftUI

struct PresetCard: View {
    let preset: HaloPreset
    let isLocked: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
                    // Icon + Category ring
                    ZStack {
                        Circle()
                            .stroke(preset.category.color.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 50, height: 50)

                        if isActive {
                            Circle()
                                .stroke(preset.category.color, lineWidth: 2)
                                .frame(width: 50, height: 50)
                                .shadow(color: preset.category.color.opacity(0.8), radius: 8)
                        }

                        Image(systemName: preset.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isActive ? preset.category.color : HaloTheme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name)
                            .font(HaloTheme.headlineFont)
                            .foregroundColor(HaloTheme.textPrimary)
                            .lineLimit(1)

                        Text(preset.binauralHzDisplay)
                            .font(HaloTheme.captionFont)
                            .foregroundColor(preset.category.color)

                        Text(preset.tagline)
                            .font(HaloTheme.captionFont)
                            .foregroundColor(HaloTheme.textTertiary)
                            .lineLimit(2)
                    }
                }
                .padding(HaloTheme.spacingM)
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusL)
                        .fill(HaloTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: HaloTheme.radiusL)
                                .stroke(
                                    isActive
                                        ? preset.category.color.opacity(0.6)
                                        : Color.white.opacity(0.06),
                                    lineWidth: isActive ? 1.5 : 1
                                )
                        )
                )
                .shadow(
                    color: isActive ? preset.category.color.opacity(0.3) : .clear,
                    radius: 12
                )

                // Pro badge
                if isLocked {
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(HaloTheme.background)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(HaloTheme.accent)
                        )
                        .padding(10)
                }

                // Active indicator
                if isActive {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(preset.category.color)
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.75 : 1.0)
    }
}

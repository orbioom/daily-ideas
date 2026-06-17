import SwiftUI

/// Horizontal style chooser for the seven generative styles.
struct StyleSelector: View {
    @Binding var selectedStyle: WallpaperStyle
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WallpaperStyle.allCases) { style in
                        chip(style)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func chip(_ style: WallpaperStyle) -> some View {
        let isSelected = style == selectedStyle
        return Button {
            Haptics.selection(enabled: settings.hapticsEnabled)
            selectedStyle = style
        } label: {
            VStack(spacing: 6) {
                Image(systemName: style.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(style.displayName)
                    .font(Theme.rounded(12, .medium))
                    .lineLimit(1)
            }
            .frame(width: 92, height: 72)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Theme.hairline, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.white : Theme.ink)
        }
        .accessibilityLabel(style.displayName)
        .accessibilityHint(style.blurb)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

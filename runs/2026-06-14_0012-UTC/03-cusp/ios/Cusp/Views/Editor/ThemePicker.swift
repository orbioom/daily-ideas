import SwiftUI

/// Horizontal swatch picker for the 8 gradient themes. Pro-only swatches show a
/// small lock and route to the paywall instead of selecting.
struct ThemePicker: View {
    @Binding var selectedTag: Int
    let isPro: Bool
    var onLocked: () -> Void

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CardTheme.allCases) { theme in
                    swatch(theme)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func swatch(_ theme: CardTheme) -> some View {
        let isSelected = selectedTag == theme.rawValue
        let locked = !Pro.canUse(theme: theme, isPro: isPro)
        return Button {
            if locked {
                Haptics.warning(enabled: settings.hapticsEnabled)
                onLocked()
            } else {
                Haptics.selection(enabled: settings.hapticsEnabled)
                selectedTag = theme.rawValue
            }
        } label: {
            ZStack {
                Circle()
                    .fill(theme.gradient)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    )
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
                if isSelected {
                    Circle()
                        .strokeBorder(Theme.accent, lineWidth: 3)
                        .frame(width: 56, height: 56)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.name)\(locked ? ", locked, Pro" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

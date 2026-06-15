import SwiftUI

/// Full-width primary action button in Stash's language.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(enabled ? Theme.accent : Theme.inkFaint)
            )
        }
        .disabled(!enabled)
    }
}

/// A pill-shaped secondary button / chip.
struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    var selected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 13, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title).font(Theme.rounded(14, .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? Color.white : Theme.ink)
            .background(
                Capsule().fill(selected ? Theme.accent : Theme.surfaceAlt)
            )
        }
    }
}

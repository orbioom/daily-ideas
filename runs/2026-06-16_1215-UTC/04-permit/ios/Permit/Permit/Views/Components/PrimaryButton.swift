import SwiftUI

/// The app's main call-to-action button style.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(fill ? Theme.onAccent : Theme.accent)
            .background(
                Group {
                    if fill {
                        Theme.heroGradient
                    } else {
                        Theme.accent.opacity(0.12)
                    }
                },
                in: RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A secondary tappable tile used for the home actions (Quick / Weak / Review).
struct ActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                    Text(subtitle).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(subtitle)
    }
}

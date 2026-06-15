import SwiftUI

/// A small rounded label pill — used for repeat summaries, mission tags, "Pro", etc.
struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var fill: Color = Theme.accentSoft
    var foreground: Color = Theme.accent

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(fill))
    }
}

/// A small "PRO" lock badge.
struct ProBadge: View {
    var body: some View {
        Pill(text: "PRO", systemImage: "lock.fill",
             fill: Theme.accent, foreground: .white)
            .accessibilityLabel("Pro feature")
    }
}

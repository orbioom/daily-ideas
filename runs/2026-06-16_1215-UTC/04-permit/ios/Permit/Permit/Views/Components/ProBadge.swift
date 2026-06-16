import SwiftUI

/// Small "PRO" lock pill used on gated rows.
struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
            Text("PRO").font(Theme.rounded(11, .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(Theme.onAccent)
        .background(Theme.accentDeep, in: Capsule())
        .accessibilityLabel("Pro feature, locked")
    }
}

/// A compact banner inviting the user to unlock Pro.
struct ProInlineBanner: View {
    let message: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Theme.onAccent)
                    .accessibilityHidden(true)
                Text(message)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.onAccent.opacity(0.85))
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Permit Pro upgrade screen")
    }
}

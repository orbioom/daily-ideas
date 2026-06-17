import SwiftUI

/// A calm, reusable empty state with an icon, message, and optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.subtleCardGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(16, .semibold))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Theme.heroGradient, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
                .accessibilityHint("Opens the creation flow")
            }
        }
        .padding(32)
        .frame(maxWidth: 420)
    }
}

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .font(Theme.rounded(20, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(16, .semibold))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
                .accessibilityHint("Adds your first item")
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

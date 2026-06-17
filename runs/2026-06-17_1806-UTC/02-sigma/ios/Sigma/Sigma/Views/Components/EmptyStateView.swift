import SwiftUI

/// A calm, reusable empty-state with an icon, message and optional call to action.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.accentInk)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accent))
                }
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

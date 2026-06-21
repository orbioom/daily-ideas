import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(IvoryTheme.accent.opacity(0.6))
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(IvoryTheme.primaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(IvoryTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

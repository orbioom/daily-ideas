import SwiftUI

struct EmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon).font(.system(size: 56)).foregroundStyle(TricksTheme.accent.opacity(0.6)).accessibilityHidden(true)
            Text(title).font(.title3.bold()).foregroundStyle(TricksTheme.primaryText)
            Text(message).font(.subheadline).foregroundStyle(TricksTheme.secondaryText).multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
        }
    }
}

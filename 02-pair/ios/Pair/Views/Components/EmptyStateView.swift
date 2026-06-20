import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(PairTheme.accent.opacity(0.6))

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(PairTheme.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(PairTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "chart.bar",
        title: "No Games Yet",
        message: "Play your first game to see stats here."
    )
    .background(PairTheme.background)
}

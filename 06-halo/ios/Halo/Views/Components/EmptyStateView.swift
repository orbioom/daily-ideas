import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: HaloTheme.spacingL) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(HaloTheme.textTertiary)

            VStack(spacing: HaloTheme.spacingS) {
                Text(title)
                    .font(HaloTheme.titleFont)
                    .foregroundColor(HaloTheme.textSecondary)

                Text(message)
                    .font(HaloTheme.bodyFont)
                    .foregroundColor(HaloTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, HaloTheme.spacingXL)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

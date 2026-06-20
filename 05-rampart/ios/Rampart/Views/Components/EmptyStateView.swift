import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"

    var body: some View {
        VStack(spacing: RampartTheme.spacingL) {
            Text(icon).font(.system(size: 60))
            Text(title)
                .font(RampartTheme.headlineFont)
                .foregroundStyle(RampartTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(RampartTheme.bodyFont)
                .foregroundStyle(RampartTheme.textSecondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(RampartTheme.labelFont)
                        .foregroundStyle(RampartTheme.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(RampartTheme.gold)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(RampartTheme.spacingXL)
    }
}

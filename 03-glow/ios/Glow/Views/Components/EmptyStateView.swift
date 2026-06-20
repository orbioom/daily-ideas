import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: GlowTheme.largeSpacing) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(GlowTheme.primary)

            VStack(spacing: GlowTheme.smallSpacing) {
                Text(title)
                    .font(GlowTheme.titleFont)
                    .foregroundStyle(GlowTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(GlowTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, GlowTheme.horizontalPadding)
            }

            if let label = actionLabel, let action = action {
                Button(action: action) {
                    Text(label)
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(GlowTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No Ingredients Found",
        message: "Try searching for an ingredient name or alias, like \"Vitamin C\" or \"Niacinamide\".",
        actionLabel: "Clear Search",
        action: {}
    )
}

import SwiftUI

/// A calm empty-state placeholder used wherever a collection can be empty.
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AbodeTheme.accentSoft)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AbodeTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(AbodeSecondaryButtonStyle())
                    .padding(.top, 4)
                    .padding(.horizontal, 40)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A loading state with a spinner and a short message (e.g. building a schedule).
struct LoadingStateView: View {
    @Environment(\.colorScheme) private var scheme
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(AbodeTheme.accent)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// A locked-feature panel that routes to the paywall. Used to gate Pro screens.
struct ProLockView: View {
    @Environment(\.colorScheme) private var scheme
    let feature: String
    let detail: String
    @Binding var showPaywall: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AbodeTheme.accent)
                .accessibilityHidden(true)
            Text(feature)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AbodeTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
            Button("Unlock Abode Pro") { showPaywall = true }
                .buttonStyle(AbodePrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the upgrade screen")
    }
}

import SwiftUI

/// Calm, recoverable screen shown if the data store cannot be created.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Ascend couldn't open its workout database. Free up some space and relaunch the app to try again.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .padding(28)
        }
    }
}

/// Inline loading state with a label.
struct LoadingView: View {
    let label: String
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(label)
    }
}

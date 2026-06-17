import SwiftUI

/// Calm, recoverable screen shown if the data store can't be created.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(Theme.serif(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Upkeep couldn't open its local database. Restarting the app usually resolves this. Your home data is stored only on this device.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }
            .padding(28)
        }
    }
}

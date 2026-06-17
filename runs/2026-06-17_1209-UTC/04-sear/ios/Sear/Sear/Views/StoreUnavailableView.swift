import SwiftUI

/// Calm, recoverable screen shown if the data store cannot be created at all.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "flame.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Sear can't open its cookbook")
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("Storage is unavailable right now. Free up some space on your device and reopen the app.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .padding(28)
        }
    }
}

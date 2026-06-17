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
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Wake couldn't open its workout library on this device. Free up some space, then reopen the app.")
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .padding(24)
        }
    }
}

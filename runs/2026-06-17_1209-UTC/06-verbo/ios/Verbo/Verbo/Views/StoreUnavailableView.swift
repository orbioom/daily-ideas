import SwiftUI

/// Calm, recoverable screen shown if the data store cannot be created.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Verbo couldn't open its local database. Restarting the app usually fixes this. Your purchases and settings are safe.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(28)
        }
    }
}

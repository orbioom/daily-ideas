import SwiftUI

/// Calm, recoverable screen shown if the data store cannot be created at all.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "tray.full")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Nest can't open right now")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Your savings data couldn't be loaded. Please relaunch the app. Your information has not been deleted.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(32)
        }
    }
}

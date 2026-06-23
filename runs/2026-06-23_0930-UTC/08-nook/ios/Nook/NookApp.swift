import SwiftUI
import SwiftData

@main
struct NookApp: App {
    /// Built once. If both on-disk and in-memory stores fail, we show a calm
    /// recoverable error screen instead of crashing.
    private let container: ModelContainer? = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
                    .tint(Theme.accent)
            } else {
                StorageErrorView()
            }
        }
    }
}

/// Shown only if SwiftData cannot open any store. Offers a guided recovery path.
struct StorageErrorView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(Theme.overdue)
                .accessibilityHidden(true)
            Text("Storage unavailable")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("Nook couldn't open its local database. Restart the app, and if this keeps happening, free up device storage and try again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
}

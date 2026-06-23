import SwiftUI
import SwiftData

@main
struct EmberApp: App {
    private let container: ModelContainer?

    init() {
        container = PersistenceController.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .tint(Theme.accent)
                    .modelContainer(container)
            } else {
                // Calm, recoverable error screen if persistence cannot start at all.
                StorageErrorView()
                    .tint(Theme.accent)
            }
        }
    }
}

/// Shown only in the extremely rare case the data store cannot be created.
private struct StorageErrorView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text("Storage unavailable")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("Ember couldn't open its data store. Please restart the app. If this keeps happening, free up some device storage and try again.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .emberScreenBackground()
        .accessibilityElement(children: .combine)
    }
}

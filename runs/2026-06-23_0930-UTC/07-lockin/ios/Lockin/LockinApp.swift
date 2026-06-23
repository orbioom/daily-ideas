import SwiftUI
import SwiftData

@main
struct LockinApp: App {
    /// Nil only in the extremely unlikely case that neither a disk nor an in-memory
    /// store can be created; the UI then shows a calm, recoverable error instead of crashing.
    private let container: ModelContainer?

    init() {
        let schema = Schema([Project.self, FocusSession.self, AppSettings.self])
        if let disk = try? ModelContainer(for: schema) {
            container = disk
        } else {
            // Disk store unavailable (e.g. a migration issue) — fall back to an in-memory
            // store so the app still launches in a usable state instead of crashing.
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: memoryConfig)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
            } else {
                StorageUnavailableView()
            }
        }
    }
}

/// Shown only if no data store could be created at all — a graceful dead-end-free fallback.
private struct StorageUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.Palette.appBackground.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.Palette.brand)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("Lockin couldn't open its data store. Restart the app to try again — your device may be low on space.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.xxl)
        }
    }
}

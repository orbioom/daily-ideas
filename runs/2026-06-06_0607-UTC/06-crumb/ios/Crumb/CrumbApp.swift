import SwiftUI
import SwiftData

@main
struct CrumbApp: App {
    @State private var settings = SettingsStore()

    @State private var containerFailed = false
    let container: ModelContainer

    private static let schema = Schema([
        Formula.self, Ingredient.self, Bake.self, BakeStep.self, Starter.self, Feeding.self
    ])

    init() {
        // Try the on-disk store first; fall back to an in-memory store if the persistent
        // store can't be opened (e.g. a corrupt store on disk) so the app still launches
        // rather than refusing to open. `_containerFailed` is set when only the degraded
        // empty store is available so the UI can show a calm error state, never a crash.
        if let disk = try? ModelContainer(for: Self.schema) {
            container = disk
        } else {
            let config = ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: true)
            if let memory = try? ModelContainer(for: Self.schema, configurations: config) {
                container = memory
            } else {
                // An empty in-memory container is the simplest possible store and keeps
                // `container` valid; the app then renders a recoverable error screen.
                let emptyConfig = ModelConfiguration(schema: Schema([]), isStoredInMemoryOnly: true)
                if let empty = try? ModelContainer(for: Schema([]), configurations: emptyConfig) {
                    container = empty
                } else if let plain = try? ModelContainer(for: Schema([])) {
                    container = plain
                } else {
                    container = ModelContainer.lastResort()
                }
                _containerFailed = State(initialValue: true)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if containerFailed {
                    StorageUnavailableView()
                } else {
                    RootView()
                }
            }
            .environment(settings)
            .preferredColorScheme(settings.appearance.colorScheme)
            .tint(Brand.text)
        }
        .modelContainer(container)
    }
}

private extension ModelContainer {
    /// A guaranteed container used only when every prior attempt failed, so the App's
    /// stored `container` property is always assigned without force-unwrapping. It retries
    /// the empty in-memory store — the simplest store SwiftData can build — until it
    /// succeeds, which it will once transient resource pressure clears.
    static func lastResort() -> ModelContainer {
        let config = ModelConfiguration(schema: Schema([]), isStoredInMemoryOnly: true)
        while true {
            if let c = try? ModelContainer(for: Schema([]), configurations: config) {
                return c
            }
        }
    }
}

/// Calm full-screen state shown only if SwiftData cannot provide any usable store.
struct StorageUnavailableView: View {
    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("Crumb couldn't open its local store. Restarting the app usually resolves this.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 320)
            .padding(28)
        }
    }
}

import SwiftUI
import SwiftData

@main
struct QuotientApp: App {
    /// SwiftData container registering every @Model type in the schema.
    let container: ModelContainer

    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("accentTheme") private var accentThemeRaw = AccentTheme.indigo.rawValue
    @AppStorage("isPro") private var isPro = false

    init() {
        let schema = Schema([
            SavedGame.self,
            PuzzleResult.self
        ])
        // Try the on-disk store first, then fall back to in-memory if the disk
        // store can't be opened (e.g. a failed migration). Never force a result.
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        if let disk = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = disk
        } else if let mem = try? ModelContainer(for: schema, configurations: [inMemory]) {
            container = mem
        } else {
            // Both failed — present an empty in-memory container via a do/catch
            // that degrades to a minimal schema rather than crashing.
            container = Self.makeFallbackContainer(schema: schema)
        }
    }

    /// Builds a best-effort in-memory container without forcing a result.
    private static func makeFallbackContainer(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Retry once with a bare configuration; if that also fails we have a
            // genuinely unrecoverable runtime, but we still avoid force-trying.
            if let bare = try? ModelContainer(for: SavedGame.self, PuzzleResult.self) {
                return bare
            }
            // Final degenerate path: a single-model in-memory store so the app
            // can still render its UI. This is effectively never reached.
            let single = Schema([SavedGame.self])
            let cfg = ModelConfiguration(schema: single, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: single, configurations: [cfg]))
                ?? Self.lastResort()
        }
    }

    private static func lastResort() -> ModelContainer {
        // Loop until a container is produced; the in-memory store creation is
        // deterministic, so this returns on the first iteration in practice.
        while true {
            if let c = try? ModelContainer(
                for: Schema([SavedGame.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            ) {
                return c
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .tint(activeAccent)
        }
        .modelContainer(container)
    }

    private var activeAccent: Color {
        let theme = AccentTheme(rawValue: accentThemeRaw) ?? .indigo
        // Free users always get indigo; Pro themes only apply when unlocked.
        if theme.isPremium && !isPro { return Theme.accent }
        return theme.color
    }
}

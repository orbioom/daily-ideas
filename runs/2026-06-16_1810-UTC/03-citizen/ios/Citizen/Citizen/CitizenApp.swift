import SwiftUI
import SwiftData

@main
struct CitizenApp: App {

    /// Single SwiftData container registering EVERY @Model type in the schema.
    /// Optional so a catastrophic store failure surfaces a calm error screen
    /// instead of crashing the process.
    private let container: ModelContainer?

    @AppStorage("hasSeeded") private var hasSeeded: Bool = false

    init() {
        let schema = Schema([
            QuestionStat.self,
            ExamResult.self,
        ])

        // Prefer the on-disk store; fall back to in-memory if it can't be opened
        // (e.g. an incompatible migration). The user keeps studying either way.
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = c
        } else {
            let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [inMemory])
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
                    .task {
                        if !hasSeeded {
                            SeedData.seedIfNeeded(context: container.mainContext)
                            hasSeeded = true
                        }
                    }
            } else {
                StoreUnavailableView()
            }
        }
    }
}

/// Calm, recoverable error scene shown only if SwiftData cannot be initialized at all.
private struct StoreUnavailableView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Storage Unavailable")
                .font(Theme.title)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text("Citizen couldn\u{2019}t open its study database. Please restart the app. If this keeps happening, free up some device storage and try again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground(scheme)
    }
}

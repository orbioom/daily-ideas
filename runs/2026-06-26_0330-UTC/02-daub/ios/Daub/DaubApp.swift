import SwiftUI
import SwiftData

@main
struct DaubApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: PuzzleProgress.self, DaubSettings.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @Query private var settingsAll: [DaubSettings]
    @Environment(\.modelContext) private var context

    var settings: DaubSettings {
        if let s = settingsAll.first { return s }
        let s = DaubSettings()
        context.insert(s)
        try? context.save()
        return s
    }

    var body: some View {
        if !settings.hasSeenOnboarding {
            OnboardingView(hasSeenOnboarding: Binding(
                get: { settings.hasSeenOnboarding },
                set: { v in
                    settings.hasSeenOnboarding = v
                    try? context.save()
                }
            ))
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "square.grid.2x2.fill")
                }

            StatsView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(DaubTheme.accent)
    }
}

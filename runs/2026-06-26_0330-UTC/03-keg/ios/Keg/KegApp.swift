import SwiftUI
import SwiftData

@main
struct KegApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                Recipe.self,
                RecipeIngredient.self,
                BrewBatch.self,
                FermentationLog.self,
                KegSettings.self
            )
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
    @Query private var settingsAll: [KegSettings]
    @Environment(\.modelContext) private var context

    var settings: KegSettings {
        if let s = settingsAll.first { return s }
        let s = KegSettings()
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
                    if v { SeedData.seedIfNeeded(context: context) }
                    try? context.save()
                }
            ))
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @Query private var recipes: [Recipe]

    var activeBatches: Int {
        recipes.flatMap { $0.batches }.filter { ["fermenting","conditioning"].contains($0.status) }.count
    }

    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "flask.fill")
                }

            BatchListView()
                .tabItem {
                    Label("Batches", systemImage: "list.bullet.clipboard.fill")
                }
                .badge(activeBatches > 0 ? "\(activeBatches)" : nil)

            CalculatorView()
                .tabItem {
                    Label("Calculators", systemImage: "slider.horizontal.3")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(KegTheme.accent)
    }
}

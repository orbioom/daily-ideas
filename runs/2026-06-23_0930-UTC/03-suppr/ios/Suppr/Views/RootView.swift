import SwiftUI
import SwiftData

/// Top-level view: gates onboarding behind a persisted flag, then shows tabs.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView { hasOnboarded = true }
            }
        }
        .tint(Theme.terracotta)
        .onAppear { syncHaptics() }
        .onChange(of: settingsList.first?.hapticsEnabled) { _, _ in syncHaptics() }
    }

    private func syncHaptics() {
        let settings = settingsList.first ?? PersistenceController.settings(in: context)
        Haptics.enabled = settings.hapticsEnabled
    }
}

/// Five-tab layout: Plan / Recipes / Grocery / Pantry / Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book.closed") }
            GroceryView()
                .tabItem { Label("Grocery", systemImage: "cart") }
            PantryView()
                .tabItem { Label("Pantry", systemImage: "cabinet") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.preview)
}

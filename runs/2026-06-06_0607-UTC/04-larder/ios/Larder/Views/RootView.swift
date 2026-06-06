import SwiftUI
import SwiftData

/// Root container: seeds sample data once, gates onboarding, hosts the tab bar.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var items: [Item]
    @Query private var locations: [Location]

    var body: some View {
        ZStack {
            Brand.pageBackground

            if !settings.hasOnboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                TabView {
                    InventoryView()
                        .tabItem { Label("Inventory", systemImage: "cabinet.fill") }
                    DashboardView()
                        .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent") }
                    ShoppingListView()
                        .tabItem { Label("Shopping", systemImage: "cart.fill") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: settings.hasOnboarded)
        .task { seedIfNeeded() }
    }

    /// Insert the starter larder exactly once, on the very first launch into an empty store.
    private func seedIfNeeded() {
        guard !settings.hasSeeded, items.isEmpty, locations.isEmpty else { return }
        SampleData.insert(into: context)
        settings.hasSeeded = true
    }
}

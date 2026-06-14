import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample data on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            CookNowScreen()
                .tabItem { Label("Cook Now", systemImage: "flame") }

            PantryScreen()
                .tabItem { Label("Pantry", systemImage: "refrigerator") }

            RecipesScreen()
                .tabItem { Label("Recipes", systemImage: "book") }

            ShoppingListScreen()
                .tabItem { Label("Shopping", systemImage: "cart") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

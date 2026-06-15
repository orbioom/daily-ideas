import SwiftData
import SwiftUI

/// The main tab interface: Library, Favorites, and Settings.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasSeeded") private var hasSeeded = false

    var body: some View {
        TabView {
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .task {
            if !hasSeeded {
                SeedData.seedIfNeeded(context: context)
                hasSeeded = true
            }
        }
    }
}

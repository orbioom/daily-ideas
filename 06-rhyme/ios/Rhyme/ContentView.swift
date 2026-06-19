import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("Rhyme", systemImage: "magnifyingglass") }
            LyricPadView()
                .tabItem { Label("Lyrics", systemImage: "doc.text") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
            DailyWordView()
                .tabItem { Label("Daily", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.pink)
    }
}

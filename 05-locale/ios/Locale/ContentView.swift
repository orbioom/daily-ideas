import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PhrasesView()
                .tabItem {
                    Label("Phrases", systemImage: "text.bubble.fill")
                }

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }

            LanguagesView()
                .tabItem {
                    Label("Languages", systemImage: "globe")
                }

            LocaleSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

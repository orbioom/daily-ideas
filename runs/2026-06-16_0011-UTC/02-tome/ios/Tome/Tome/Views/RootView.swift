import SwiftUI
import SwiftData

/// Root tab container: 4 feature tabs + Settings.
struct RootView: View {
    var body: some View {
        TabView {
            ReadingView()
                .tabItem { Label("Reading", systemImage: "book.fill") }

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.pie.fill") }

            TBRView()
                .tabItem { Label("To Read", systemImage: "bookmark.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

import SwiftUI
import SwiftData

/// Root tab container — four feature tabs plus Settings.
struct RootView: View {
    var body: some View {
        TabView {
            TimelineScreen()
                .tabItem { Label("Timeline", systemImage: "calendar") }

            ShowsScreen()
                .tabItem { Label("Shows", systemImage: "music.note.list") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            BucketListScreen()
                .tabItem { Label("Bucket List", systemImage: "star") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

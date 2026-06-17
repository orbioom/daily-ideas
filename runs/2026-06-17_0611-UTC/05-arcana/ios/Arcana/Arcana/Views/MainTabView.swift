import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            SpreadsView()
                .tabItem { Label("Spreads", systemImage: "rectangle.3.group.fill") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

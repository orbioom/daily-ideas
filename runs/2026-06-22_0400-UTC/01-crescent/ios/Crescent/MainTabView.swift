import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Tonight", systemImage: "moon.stars.fill") }

            MoonCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            JournalListView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }

            RitualsView()
                .tabItem { Label("Rituals", systemImage: "sparkles") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
        .tint(CrescentTheme.gold)
        .preferredColorScheme(.dark)
    }
}

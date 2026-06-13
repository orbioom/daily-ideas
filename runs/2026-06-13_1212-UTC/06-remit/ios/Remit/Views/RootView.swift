import SwiftUI

/// The four feature tabs plus Settings. Each tab owns its own NavigationStack.
struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            UpcomingView()
                .tabItem { Label("Upcoming", systemImage: "tray.full.fill") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            BillsView()
                .tabItem { Label("Bills", systemImage: "list.bullet.rectangle.portrait.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

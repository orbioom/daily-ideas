import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "rectangle.3.group") }
                .tag(0)

            SubscriptionsView()
                .tabItem { Label("Subscriptions", systemImage: "square.stack.3d.up") }
                .tag(1)

            CalendarInsightsView()
                .tabItem { Label("Insights", systemImage: "calendar") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .tint(RecurTheme.violet)
    }
}

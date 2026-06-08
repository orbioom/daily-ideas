import SwiftUI

struct MainTabs: View {
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            PlantsView()
                .tabItem {
                    Label("Plants", systemImage: "leaf.fill")
                }

            RoomsView()
                .tabItem {
                    Label("Rooms", systemImage: "house.fill")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

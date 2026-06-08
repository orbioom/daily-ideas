import SwiftUI

struct MainTabs: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TimelineLogView()
                .tabItem {
                    Label("Timeline", systemImage: "list.bullet.rectangle.fill")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            BabiesView()
                .tabItem {
                    Label("Babies", systemImage: "person.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Brand.text)
    }
}

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "bolt.fill")
                }
            SessionListView()
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }
            VehicleListView()
                .tabItem {
                    Label("Vehicles", systemImage: "car.fill")
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

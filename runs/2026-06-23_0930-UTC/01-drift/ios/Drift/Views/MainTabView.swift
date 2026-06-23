import SwiftUI

/// Five-tab home: Tonight / Log / Trends / Routine / Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            TonightView()
                .tabItem { Label("Tonight", systemImage: "moon.stars.fill") }

            LogListView()
                .tabItem { Label("Log", systemImage: "bed.double.fill") }

            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }

            RoutineView()
                .tabItem { Label("Routine", systemImage: "checklist") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

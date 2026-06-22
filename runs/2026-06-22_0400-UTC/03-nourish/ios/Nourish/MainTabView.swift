import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FoodLogView()
                .tabItem { Label("Food Log", systemImage: "fork.knife") }
                .tag(0)
            SymptomsView()
                .tabItem { Label("Symptoms", systemImage: "waveform.path.ecg") }
                .tag(1)
            EliminationView()
                .tabItem { Label("Protocol", systemImage: "list.bullet.clipboard.fill") }
                .tag(2)
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(4)
        }
        .tint(NourishTheme.sage)
    }
}

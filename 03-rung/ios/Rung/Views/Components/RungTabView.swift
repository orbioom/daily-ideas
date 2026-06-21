import SwiftUI

struct RungTabView: View {
    var body: some View {
        TabView {
            RungDailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }
            RungPracticeView()
                .tabItem { Label("Practice", systemImage: "shuffle") }
            RungStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            RungSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.green)
    }
}

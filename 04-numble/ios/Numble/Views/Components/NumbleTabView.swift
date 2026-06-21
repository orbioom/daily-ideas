import SwiftUI

struct NumbleTabView: View {
    var body: some View {
        TabView {
            NumbleGameView()
                .tabItem { Label("Play", systemImage: "function") }
            NumbleStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            NumbleSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.purple)
    }
}

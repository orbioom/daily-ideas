import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GameView()
                .tabItem {
                    Label("Play", systemImage: "circle.grid.3x3.fill")
                }

            DailyView()
                .tabItem {
                    Label("Daily", systemImage: "calendar.circle.fill")
                }

            RecordsView()
                .tabItem {
                    Label("Records", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.purple)
    }
}

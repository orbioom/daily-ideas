import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            TimerSetupView()
                .tabItem { Label("Session", systemImage: "timer") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }

            ProtocolsView()
                .tabItem { Label("Protocols", systemImage: "list.bullet.clipboard.fill") }

            MistSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.2, green: 0.85, blue: 0.85))
    }
}

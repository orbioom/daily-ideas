import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Daily", systemImage: "calendar") }
            PacksView()
                .tabItem { Label("Packs", systemImage: "square.grid.2x2") }
            ArchiveView()
                .tabItem { Label("Archive", systemImage: "clock") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.purple)
    }
}

import SwiftUI

struct ContentView: View {
    @State private var vm = GameViewModel()

    var body: some View {
        TabView {
            BoardView(vm: vm)
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }

            ScribeStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            ScribeSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

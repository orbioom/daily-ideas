import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var didSeed = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            ToolsView()
                .tabItem { Label("Tools", systemImage: "waveform.path") }

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .task {
            guard !didSeed else { return }
            didSeed = true
            SeedData.seedIfNeeded(context)
        }
    }
}

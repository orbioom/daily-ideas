import SwiftUI

/// The four feature tabs plus Settings. Each tab owns its own NavigationStack.
struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            ChordsView()
                .tabItem { Label("Chords", systemImage: "square.grid.3x3.fill") }
            FretboardView()
                .tabItem { Label("Fretboard", systemImage: "guitars.fill") }
            ChangesView()
                .tabItem { Label("Changes", systemImage: "metronome.fill") }
            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

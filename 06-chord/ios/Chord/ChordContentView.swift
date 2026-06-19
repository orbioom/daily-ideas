import SwiftUI

struct ChordContentView: View {
    @AppStorage(ChordSettings.onboardingDone) private var onboardingDone = false

    var body: some View {
        if !onboardingDone {
            ChordOnboardingView()
        } else {
            ChordTabView()
        }
    }
}

struct ChordTabView: View {
    var body: some View {
        TabView {
            ProgressionsView()
                .tabItem { Label("Progressions", systemImage: "music.note.list") }

            InspireView()
                .tabItem { Label("Inspire", systemImage: "sparkles") }

            ChordStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            ChordSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(ChordTheme.teal)
    }
}

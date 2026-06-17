import SwiftUI

/// The root tabbed experience: Tuner, Metronome, Tunings, Tone, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            TunerView()
                .tabItem { Label("Tuner", systemImage: "tuningfork") }

            MetronomeView()
                .tabItem { Label("Metronome", systemImage: "metronome.fill") }

            TuningsView()
                .tabItem { Label("Tunings", systemImage: "slider.horizontal.3") }

            ToneView()
                .tabItem { Label("Tone", systemImage: "waveform") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(PitchTheme.indigo)
    }
}

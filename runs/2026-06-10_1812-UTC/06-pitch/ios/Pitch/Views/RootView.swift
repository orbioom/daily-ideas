import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        ZStack {
            if hasOnboarded { MainTabView() } else { OnboardingView() }
        }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }
}

struct MainTabView: View {
    @StateObject private var metronome: MetronomeController

    init() {
        // The metronome shares the app's ToneEngine, injected after creation.
        _metronome = StateObject(wrappedValue: MetronomeController(tone: ToneEngine.shared))
    }

    var body: some View {
        TabView {
            TunerView()
                .tabItem { Label("Tuner", systemImage: "tuningfork") }
            TuningsView()
                .tabItem { Label("Tunings", systemImage: "guitars.fill") }
            MetronomeView()
                .environmentObject(metronome)
                .tabItem { Label("Metronome", systemImage: "metronome.fill") }
            ReferenceView()
                .tabItem { Label("Pitches", systemImage: "pianokeys") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Brand.text)
    }
}

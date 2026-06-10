import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("appearance") private var appearance = "system"

    private var scheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    var body: some View {
        ZStack {
            if onboarded {
                MainTabView()
            } else {
                OnboardingView { withAnimation(Brand.ease()) { onboarded = true } }
            }
        }
        .animation(Brand.ease(), value: onboarded)
        .preferredColorScheme(scheme)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TunerView()
                .tabItem { Label("Tuner", systemImage: "tuningfork") }
            MetronomeView()
                .tabItem { Label("Metronome", systemImage: "metronome") }
            TonesView()
                .tabItem { Label("Tones", systemImage: "speaker.wave.2") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}

#Preview {
    RootView().modelContainer(for: [Tuning.self, MetronomePreset.self], inMemory: true)
}

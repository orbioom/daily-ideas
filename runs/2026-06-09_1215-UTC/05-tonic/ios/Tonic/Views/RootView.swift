import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("tonic.onboarded") private var onboarded = false
    @AppStorage("tonic.haptics") private var haptics = true
    @AppStorage("tonic.volume") private var volume = 0.8
    @AppStorage("tonic.noteDuration") private var noteDuration = 0.6
    @AppStorage("tonic.waveform") private var waveform = Waveform.sine.rawValue

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x7A6CC0))
        .onAppear { configureAudio() }
        .onChange(of: onboarded) { _, _ in SeedData.seedIfNeeded(context) }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
        .onChange(of: volume) { _, new in ToneSynth.shared.volume = Float(new) }
        .onChange(of: noteDuration) { _, new in ToneSynth.shared.noteDurationSec = new }
        .onChange(of: waveform) { _, new in ToneSynth.shared.waveformRaw = new }
    }

    private func configureAudio() {
        Haptics.enabled = haptics
        ToneSynth.shared.enabled = true
        ToneSynth.shared.volume = Float(volume)
        ToneSynth.shared.noteDurationSec = noteDuration
        ToneSynth.shared.waveformRaw = waveform
        SeedData.seedIfNeeded(context)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { PracticeHomeView() }
                .tabItem { Label("Practice", systemImage: "ear") }
            NavigationStack { DrillsView() }
                .tabItem { Label("Drills", systemImage: "slider.horizontal.3") }
            NavigationStack { ProgressView_Tonic() }
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hush.onboarded") private var onboarded = false
    @AppStorage("hush.haptics") private var haptics = true
    @AppStorage("hush.masterVolume") private var masterVolume = 0.9
    @AppStorage("hush.defaultLayerVolume") private var defaultLayerVolume = 0.7
    @AppStorage("hush.defaultFade") private var defaultFade = 30.0

    @State private var engine = MixerEngine()

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x6A6FB0))
        .environment(engine)
        .onAppear {
            Haptics.enabled = haptics
            engine.masterVolume = masterVolume
            engine.defaultLayerVolume = defaultLayerVolume
            engine.fadeSeconds = defaultFade
            SeedData.seedIfNeeded(context)
        }
        .onChange(of: onboarded) { _, _ in SeedData.seedIfNeeded(context) }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
        .onChange(of: masterVolume) { _, new in engine.masterVolume = new }
        .onChange(of: defaultLayerVolume) { _, new in engine.defaultLayerVolume = new }
        .onChange(of: defaultFade) { _, new in engine.fadeSeconds = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            MixerView()
                .tabItem { Label("Mixer", systemImage: "slider.vertical.3") }
            MixesView()
                .tabItem { Label("Mixes", systemImage: "square.stack") }
            SleepTimerView()
                .tabItem { Label("Sleep", systemImage: "moon.zzz.fill") }
            SoundLibraryView()
                .tabItem { Label("Sounds", systemImage: "waveform") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

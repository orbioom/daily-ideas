import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("chime.onboarded") private var onboarded = false
    @AppStorage("chime.haptics") private var haptics = true
    @AppStorage("chime.bellVolume") private var bellVolume = 0.8

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x4F8FA8))
        .onAppear {
            Haptics.enabled = haptics
            BellPlayer.shared.enabled = true
            BellPlayer.shared.volume = Float(bellVolume)
            SeedData.seedIfNeeded(context)
        }
        .onChange(of: onboarded) { _, _ in SeedData.seedIfNeeded(context) }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
        .onChange(of: bellVolume) { _, new in BellPlayer.shared.volume = Float(new) }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TimerHomeView()
                .tabItem { Label("Sit", systemImage: "timer") }
            PresetsView()
                .tabItem { Label("Presets", systemImage: "slider.horizontal.3") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

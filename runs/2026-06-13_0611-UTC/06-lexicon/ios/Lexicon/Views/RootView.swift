import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        TabView {
            DailyView().tabItem { Label("Daily", systemImage: "calendar") }
            PracticeView().tabItem { Label("Practice", systemImage: "infinity") }
            ArchiveView().tabItem { Label("Archive", systemImage: "tray.full") }
            StatsView().tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "figure.run") }
            PlanView().tabItem { Label("Plan", systemImage: "calendar") }
            HistoryView().tabItem { Label("History", systemImage: "chart.bar.fill") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

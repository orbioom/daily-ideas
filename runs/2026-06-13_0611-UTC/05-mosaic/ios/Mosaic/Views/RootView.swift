import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "camera") }
            YearView().tabItem { Label("Year", systemImage: "square.grid.3x3.fill") }
            TimelineView().tabItem { Label("Timeline", systemImage: "rectangle.stack") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

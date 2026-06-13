import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "sun.max") }
            LibraryView().tabItem { Label("Library", systemImage: "books.vertical") }
            HighlightsView().tabItem { Label("Highlights", systemImage: "quote.bubble") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

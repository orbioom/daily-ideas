import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        TabView {
            PipelineView()
                .tabItem { Label("Pipeline", systemImage: "tray.full.fill") }
            UpcomingView()
                .tabItem { Label("Up next", systemImage: "calendar.badge.clock" ) }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.blue)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }
}

import SwiftUI

/// The app's tab shell. Shares a single SkyViewModel across screens.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false
    @State private var sky = SkyViewModel()
    @State private var selectedTab = 0
    @State private var didSeed = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TonightView(sky: sky)
                .tabItem { Label("Tonight", systemImage: "sparkles") }
                .tag(0)

            SkyMapView(sky: sky)
                .tabItem { Label("Sky Map", systemImage: "circle.dotted") }
                .tag(1)

            SearchView(sky: sky)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(2)

            MoonView(sky: sky)
                .tabItem { Label("Moon", systemImage: "moon.stars") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
        .tint(Theme.accent)
        .task {
            if !didSeed {
                SeedData.seedIfNeeded(modelContext)
                didSeed = true
            }
        }
        .task(id: contextKey) {
            await sky.refresh(settings: settings, isPro: isPro)
        }
    }

    /// A key that changes whenever the observing context changes, retriggering compute.
    private var contextKey: String {
        let dateKey = settings.timeMode == .now ? "now" : "\(Int(settings.customDateInterval))"
        return "\(settings.selectedLocationID)|\(settings.manualLatitude)|\(settings.manualLongitude)|\(settings.timeModeRaw)|\(dateKey)|\(settings.magnitudeLimit)|\(isPro)"
    }
}

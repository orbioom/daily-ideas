import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("plume.hasOnboarded") private var hasOnboarded = false
    @AppStorage("plume.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("plume.appearance") private var appearance = "system"
    @Query private var species: [Species]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    LifeListView()
                        .tabItem { Label("Life List", systemImage: "list.star") }
                    SightingsView()
                        .tabItem { Label("Sightings", systemImage: "binoculars") }
                    TripsView()
                        .tabItem { Label("Trips", systemImage: "map") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if species.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

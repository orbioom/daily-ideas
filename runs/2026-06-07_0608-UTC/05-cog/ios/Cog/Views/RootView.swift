import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cog.hasOnboarded") private var hasOnboarded = false
    @AppStorage("cog.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("cog.appearance") private var appearance = "system"
    @Query private var bikes: [Bike]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    GarageView()
                        .tabItem { Label("Garage", systemImage: "bicycle") }
                    HealthView()
                        .tabItem { Label("Health", systemImage: "gauge.with.dots.needle.bottom.50percent") }
                    RidesView()
                        .tabItem { Label("Rides", systemImage: "road.lanes") }
                    HistoryView()
                        .tabItem { Label("Service", systemImage: "wrench.and.screwdriver") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if bikes.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

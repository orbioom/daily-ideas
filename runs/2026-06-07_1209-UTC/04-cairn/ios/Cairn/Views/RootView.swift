import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cairn.hasOnboarded") private var hasOnboarded = false
    @AppStorage("cairn.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("cairn.appearance") private var appearance = "system"
    @Query private var gear: [GearItem]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    ListsView()
                        .tabItem { Label("Lists", systemImage: "checklist") }
                    GearView()
                        .tabItem { Label("Gear", systemImage: "backpack") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.pie") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if gear.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

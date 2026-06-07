import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("vial.hasOnboarded") private var hasOnboarded = false
    @AppStorage("vial.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("vial.appearance") private var appearance = "system"
    @Query private var meds: [Medication]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    TodayView()
                        .tabItem { Label("Today", systemImage: "checklist") }
                    MedicationsView()
                        .tabItem { Label("Meds", systemImage: "pills") }
                    RefillsView()
                        .tabItem { Label("Refills", systemImage: "shippingbox") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if meds.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

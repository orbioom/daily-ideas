import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    ApiariesView()
                        .tabItem { Label("Apiaries", systemImage: "house") }
                    TasksView()
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                    HarvestView()
                        .tabItem { Label("Harvest", systemImage: "drop") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView { hasOnboarded = true }.transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: hasOnboarded)
        .task {
            Haptics.enabled = hapticsEnabled
            if !didSeed { SampleData.seed(into: context); didSeed = true }
        }
        .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
    }
}

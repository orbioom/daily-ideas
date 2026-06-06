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
                    WorkoutsView()
                        .tabItem { Label("Train", systemImage: "figure.strengthtraining.traditional") }
                    ExercisesView()
                        .tabItem { Label("Lifts", systemImage: "list.bullet.rectangle") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
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

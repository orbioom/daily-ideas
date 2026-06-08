import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("lull.onboarded") private var onboarded = false
    @AppStorage("lull.haptics") private var haptics = true

    var body: some View {
        ZStack {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView(done: Binding(get: { onboarded }, set: { onboarded = $0 }))
            }
        }
        .tint(Brand.text)
        .task { BreathPattern.ensureDefaults(in: context) }
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, v in Haptics.enabled = v }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            BreatheView()
                .tabItem { Label("Breathe", systemImage: "wind") }
            PatternsView()
                .tabItem { Label("Patterns", systemImage: "square.on.square") }
            HistoryView()
                .tabItem { Label("Sessions", systemImage: "clock.arrow.circlepath") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

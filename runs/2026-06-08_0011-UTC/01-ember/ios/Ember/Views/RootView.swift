import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("ember.onboarded") private var onboarded = false
    @AppStorage("ember.haptics") private var haptics = true

    var body: some View {
        ZStack {
            if onboarded {
                MainTabs()
                    .transition(.opacity)
            } else {
                OnboardingView(done: Binding(
                    get: { onboarded },
                    set: { onboarded = $0 }))
            }
        }
        .tint(Brand.text)
        .task { Plan.ensureDefaults(in: context) }
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet.rectangle") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            PlansView()
                .tabItem { Label("Plans", systemImage: "target") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

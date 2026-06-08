import SwiftUI

struct RootView: View {
    @AppStorage("tare.onboarded") private var onboarded = false
    @AppStorage("tare.haptics") private var haptics = true

    var body: some View {
        ZStack {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView(done: Binding(get: { onboarded }, set: { onboarded = $0 }))
            }
        }
        .tint(Brand.text)
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, v in Haptics.enabled = v }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "scalemass.fill") }
            TrendView()
                .tabItem { Label("Trend", systemImage: "chart.line.downtrend.xyaxis") }
            LogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "sparkles") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

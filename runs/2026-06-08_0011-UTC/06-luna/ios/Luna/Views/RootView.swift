import SwiftUI

struct RootView: View {
    @AppStorage("luna.onboarded") private var onboarded = false
    @AppStorage("luna.haptics") private var haptics = true

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
                .tabItem { Label("Today", systemImage: "moon.stars.fill") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            CyclesView()
                .tabItem { Label("Cycles", systemImage: "repeat") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

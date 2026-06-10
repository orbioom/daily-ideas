import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.and.horizon.fill") }
            TimelineView()
                .tabItem { Label("Journal", systemImage: "calendar") }
            ReflectView()
                .tabItem { Label("Reflect", systemImage: "sparkles") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Brand.text)
    }
}

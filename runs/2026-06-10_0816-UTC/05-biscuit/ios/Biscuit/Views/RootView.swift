import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Query private var dogs: [Dog]

    var body: some View {
        Group {
            if hasOnboarded && !dogs.isEmpty {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, enabled in Haptics.enabled = enabled }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "pawprint") }
            CurriculumView()
                .tabItem { Label("Skills", systemImage: "list.bullet.clipboard") }
            ClickerView()
                .tabItem { Label("Clicker", systemImage: "hand.tap") }
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}

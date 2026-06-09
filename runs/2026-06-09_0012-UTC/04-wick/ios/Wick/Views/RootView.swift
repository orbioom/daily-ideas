import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("wick.onboarded") private var onboarded = false
    @AppStorage("wick.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded { MainTabView() } else { OnboardingView() }
        }
        .tint(Color(hex: 0x5A6BB0))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            JournalView()
                .tabItem { Label("Journal", systemImage: "list.bullet.rectangle") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

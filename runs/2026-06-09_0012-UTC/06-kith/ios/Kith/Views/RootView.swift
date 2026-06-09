import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("kith.onboarded") private var onboarded = false
    @AppStorage("kith.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded { MainTabView() } else { OnboardingView() }
        }
        .tint(Color(hex: 0xC06A7A))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            PeopleView()
                .tabItem { Label("People", systemImage: "person.2.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("whisker.onboarded") private var onboarded = false
    @AppStorage("whisker.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0xC08A4E))
        .onAppear { Haptics.enabled = haptics }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            CareView()
                .tabItem { Label("Care", systemImage: "checklist") }
            PetsView()
                .tabItem { Label("Pets", systemImage: "pawprint.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

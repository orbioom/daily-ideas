import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hearth.onboarded") private var onboarded = false
    @AppStorage("hearth.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Brand.magic)
        .onAppear {
            Haptics.enabled = haptics
            SeedData.seedIfNeeded(context)
        }
        .onChange(of: onboarded) { _, _ in SeedData.seedIfNeeded(context) }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sparkles") }
            RoomsView()
                .tabItem { Label("Rooms", systemImage: "square.grid.2x2") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

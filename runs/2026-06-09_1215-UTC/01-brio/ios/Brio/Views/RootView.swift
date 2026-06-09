import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("brio.onboarded") private var onboarded = false
    @AppStorage("brio.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0xC0553E))
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
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "figure.run") }
            BuilderListView()
                .tabItem { Label("Build", systemImage: "hammer") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

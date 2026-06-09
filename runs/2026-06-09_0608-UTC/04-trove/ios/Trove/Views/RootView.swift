import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("trove.onboarded") private var onboarded = false
    @AppStorage("trove.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0xB0793E))
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
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { PeopleView() }
                .tabItem { Label("People", systemImage: "person.2.fill") }
            NavigationStack { OccasionsView() }
                .tabItem { Label("Occasions", systemImage: "calendar") }
            NavigationStack { InsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

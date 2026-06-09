import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("sojourn.onboarded") private var onboarded = false
    @AppStorage("sojourn.haptics") private var haptics = true

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
            PassportView()
                .tabItem { Label("Passport", systemImage: "globe") }
            ExploreView()
                .tabItem { Label("Explore", systemImage: "map") }
            WishlistView()
                .tabItem { Label("Wishlist", systemImage: "heart") }
            TripsView()
                .tabItem { Label("Trips", systemImage: "suitcase") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

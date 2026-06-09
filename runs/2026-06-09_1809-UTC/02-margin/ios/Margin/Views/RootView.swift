import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("margin.onboarded") private var onboarded = false
    @AppStorage("margin.haptics") private var haptics = true

    @State private var didSeed = false

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
            seed()
        }
        .onChange(of: onboarded) { _, _ in seed() }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }

    private func seed() {
        guard !didSeed else { return }
        didSeed = true
        SeedData.seedIfNeeded(context)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ShelfView()
                .tabItem { Label("Shelf", systemImage: "books.vertical.fill") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "magnifyingglass") }
            ChallengeView()
                .tabItem { Label("Challenge", systemImage: "target") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("mettle.onboarded") private var onboarded = false
    @AppStorage("mettle.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0xC4612F))
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
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "flame.fill") }
            NavigationStack { ChallengesView() }
                .tabItem { Label("Challenges", systemImage: "trophy.fill") }
            NavigationStack { ProgressBoardView() }
                .tabItem { Label("Progress", systemImage: "calendar") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

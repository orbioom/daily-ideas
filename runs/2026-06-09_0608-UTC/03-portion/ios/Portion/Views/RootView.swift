import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("portion.onboarded") private var onboarded = false
    @AppStorage("portion.haptics") private var haptics = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x5BA36B))
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
            NavigationStack { RecipesView() }
                .tabItem { Label("Recipes", systemImage: "list.bullet.rectangle") }
            NavigationStack { FoodsView() }
                .tabItem { Label("Foods", systemImage: "fork.knife") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

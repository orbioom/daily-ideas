import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("appearance") private var appearance = "system"

    private var scheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    var body: some View {
        ZStack {
            if onboarded {
                MainTabView()
            } else {
                OnboardingView { withAnimation(Brand.ease()) { onboarded = true } }
            }
        }
        .animation(Brand.ease(), value: onboarded)
        .preferredColorScheme(scheme)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Play", systemImage: "square.grid.3x3") }
            DailyView()
                .tabItem { Label("Daily", systemImage: "calendar") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}

#Preview {
    RootView().modelContainer(for: SudokuGame.self, inMemory: true)
}

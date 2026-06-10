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
                    .transition(.opacity)
            } else {
                OnboardingView { withAnimation(Brand.ease()) { onboarded = true } }
                    .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: onboarded)
        .preferredColorScheme(scheme)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.stack") }
            PracticeSetupView()
                .tabItem { Label("Practice", systemImage: "play.circle") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}

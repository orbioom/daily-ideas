import SwiftUI
import SwiftData

/// App root: gates onboarding, then shows the main TabView.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme

    /// Shared, app-wide preferences + lightweight services injected to all tabs.
    @State private var prefs = AppPreferences()
    @State private var speech = SpeechManager()

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(prefs)
        .environment(speech)
        .tint(Theme.accent)
        .animation(nil, value: hasOnboarded)
    }
}

/// The five primary tabs + Settings entry lives within Home's navigation bar.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            StudyView()
                .tabItem { Label("Study", systemImage: "rectangle.on.rectangle") }

            ExamHubView()
                .tabItem { Label("Exam", systemImage: "checkmark.seal") }

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }

            VocabView()
                .tabItem { Label("Vocab", systemImage: "textformat.abc") }
        }
    }
}

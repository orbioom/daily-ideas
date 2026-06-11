import SwiftUI
import SwiftData

@main
struct FlowApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                FlowRootView()
            } else {
                FlowOnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: [CompletedSession.self])
    }
}

struct FlowRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SessionsView()
                .tabItem { Label("Sessions", systemImage: "figure.yoga") }
                .tag(0)

            PoseLibraryView()
                .tabItem { Label("Poses", systemImage: "list.bullet.rectangle") }
                .tag(1)

            JournalView()
                .tabItem { Label("Journal", systemImage: "book.fill") }
                .tag(2)

            FlowSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .tint(FlowTheme.sage)
    }
}

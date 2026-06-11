import SwiftUI
import SwiftData

@main
struct CipherApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                CipherRootView()
            } else {
                CipherOnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: [PuzzleProgress.self])
    }
}

struct CipherRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PuzzleView(puzzle: CryptoPuzzle.todayPuzzle())
            }
            .tabItem { Label("Today", systemImage: "puzzlepiece.fill") }
            .tag(0)

            ArchiveView()
                .tabItem { Label("Archive", systemImage: "calendar") }
                .tag(1)

            CipherStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(2)

            CipherSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .tint(CipherTheme.amber)
    }
}

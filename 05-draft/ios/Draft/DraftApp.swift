import SwiftUI
import SwiftData

@main
struct DraftApp: App {
    var body: some Scene {
        WindowGroup {
            DraftRootView()
        }
        .modelContainer(for: [DraftProject.self, DraftCharacter.self, DraftChapter.self, DraftScene.self, PlotBeat.self])
    }
}

struct DraftRootView: View {
    @AppStorage("draftHasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            DraftContentView()
        } else {
            DraftOnboardingView()
        }
    }
}

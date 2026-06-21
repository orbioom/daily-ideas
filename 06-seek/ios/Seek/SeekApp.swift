import SwiftUI
import SwiftData

@main
struct SeekApp: App {
    var body: some Scene {
        WindowGroup {
            SeekRootView()
                .modelContainer(for: [PuzzleRecord.self, SeekSettings.self])
        }
    }
}

struct SeekRootView: View {
    @Query private var settingsList: [SeekSettings]

    var body: some View {
        if settingsList.first?.hasCompletedOnboarding == true {
            SeekContentView()
        } else {
            SeekOnboardingView()
        }
    }
}

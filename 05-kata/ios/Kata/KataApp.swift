import SwiftUI
import SwiftData

@main
struct KataApp: App {
    var body: some Scene {
        WindowGroup {
            KataRootView()
                .modelContainer(for: [WODResult.self, PersonalRecord.self, KataSettings.self])
        }
    }
}

struct KataRootView: View {
    @Query private var settingsList: [KataSettings]

    var body: some View {
        if settingsList.first?.hasCompletedOnboarding == true {
            KataContentView()
        } else {
            KataOnboardingView()
        }
    }
}

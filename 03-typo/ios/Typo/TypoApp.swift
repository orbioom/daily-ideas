import SwiftUI
import SwiftData

@main
struct TypoApp: App {
    var body: some Scene {
        WindowGroup {
            TypoRootView()
                .modelContainer(for: [TypoResult.self, TypoSettings.self])
        }
    }
}

struct TypoRootView: View {
    @Query private var settingsList: [TypoSettings]

    var body: some View {
        if settingsList.first?.hasCompletedOnboarding == true {
            TypoContentView()
        } else {
            TypoOnboardingView()
        }
    }
}

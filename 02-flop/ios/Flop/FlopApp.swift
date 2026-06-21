import SwiftUI
import SwiftData

@main
struct FlopApp: App {
    var body: some Scene {
        WindowGroup {
            FlopRootView()
                .modelContainer(for: [FlopSession.self, FlopQuizRecord.self, FlopSettings.self])
        }
    }
}

struct FlopRootView: View {
    @Query private var settings: [FlopSettings]

    var body: some View {
        if settings.first?.hasCompletedOnboarding == true {
            FlopContentView()
        } else {
            FlopOnboardingView()
        }
    }
}

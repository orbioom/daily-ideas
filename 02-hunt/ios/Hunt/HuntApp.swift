import SwiftUI
import SwiftData

@main
struct HuntApp: App {
    var body: some Scene {
        WindowGroup {
            HuntRootView()
                .modelContainer(for: HuntResult.self)
        }
    }
}

struct HuntRootView: View {
    @AppStorage("hunt_onboarding_done") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            ContentView()
        } else {
            HuntOnboardingView(onComplete: { onboardingDone = true })
        }
    }
}

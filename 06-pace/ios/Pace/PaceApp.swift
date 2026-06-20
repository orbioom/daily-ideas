import SwiftUI
import SwiftData

@main
struct PaceApp: App {
    @State private var runEngine = RunEngine()

    var body: some Scene {
        WindowGroup {
            PaceRootView()
                .modelContainer(for: [RunSession.self, RoutePoint.self])
                .environment(runEngine)
        }
    }
}

struct PaceRootView: View {
    @AppStorage("pace_onboarding_done") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            ContentView()
        } else {
            PaceOnboardingView(onComplete: { onboardingDone = true })
        }
    }
}

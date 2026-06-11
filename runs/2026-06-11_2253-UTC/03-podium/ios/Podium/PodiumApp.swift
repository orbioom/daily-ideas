import SwiftUI
import SwiftData

@main
struct PodiumApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
        }
        .modelContainer(for: [SpeechSession.self])
    }
}

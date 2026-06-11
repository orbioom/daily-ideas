import SwiftUI
import SwiftData

@main
struct HiredApp: App {
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
        .modelContainer(for: [Application.self, StageEvent.self, Interview.self,
                              JobContact.self, FollowUp.self])
    }
}

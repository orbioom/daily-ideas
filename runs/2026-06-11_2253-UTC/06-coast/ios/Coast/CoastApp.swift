import SwiftUI
import SwiftData

@main
struct CoastApp: App {
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
        .modelContainer(for: [Profile.self, NetWorthEntry.self, Milestone.self])
    }
}

import SwiftUI
import SwiftData

@main
struct FlipsideApp: App {
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
        .modelContainer(for: [Item.self, Sale.self])
    }
}

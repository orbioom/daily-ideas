import SwiftUI
import SwiftData

@main
struct BriefApp: App {
    var body: some Scene {
        WindowGroup {
            BriefRootView()
                .modelContainer(for: [Client.self, Invoice.self, LineItem.self, BriefSettings.self])
        }
    }
}

struct BriefRootView: View {
    @AppStorage("brief_onboarding_done") private var onboardingDone = false
    @AppStorage("brief_seeded") private var seeded = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if onboardingDone {
                ContentView()
                    .onAppear { seedIfNeeded() }
            } else {
                BriefOnboardingView(onComplete: {
                    onboardingDone = true
                    seedIfNeeded()
                })
            }
        }
    }

    private func seedIfNeeded() {
        guard !seeded else { return }
        seeded = true
        BriefDataSeeder.seed(in: modelContext)
    }
}

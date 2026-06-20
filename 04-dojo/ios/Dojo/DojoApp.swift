import SwiftUI
import SwiftData

@main
struct DojoApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                TrainingSession.self,
                Technique.self,
                BeltRecord.self,
                Competition.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @AppStorage("dojoOnboarded") private var onboarded = false
    @AppStorage("dojoSeeded") private var seeded = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            if !seeded {
                DojoSeeder.seed(ctx: modelContext)
                seeded = true
            }
        }
    }
}

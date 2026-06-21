import SwiftUI
import SwiftData

@main
struct CountApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TrainingRecord.self, CountSettings.self])
    }
}

struct RootView: View {
    @Query private var settingsArr: [CountSettings]
    @Environment(\.modelContext) private var ctx

    var settings: CountSettings {
        if let s = settingsArr.first { return s }
        let s = CountSettings()
        ctx.insert(s)
        return s
    }

    var body: some View {
        if settings.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView(settings: settings)
        }
    }
}

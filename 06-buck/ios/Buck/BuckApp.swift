import SwiftUI
import SwiftData

@main
struct BuckApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [EuchreGameRecord.self, BuckSettings.self])
    }
}

struct RootView: View {
    @Query private var settingsArr: [BuckSettings]
    @Environment(\.modelContext) private var ctx

    var settings: BuckSettings {
        if let s = settingsArr.first { return s }
        let s = BuckSettings()
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

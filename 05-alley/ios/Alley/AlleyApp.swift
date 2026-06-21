import SwiftUI
import SwiftData

@main
struct AlleyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [BowlingGame.self, AlleySettings.self])
    }
}

struct RootView: View {
    @Query private var settingsArr: [AlleySettings]
    @Environment(\.modelContext) private var ctx

    var settings: AlleySettings {
        if let s = settingsArr.first { return s }
        let s = AlleySettings()
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

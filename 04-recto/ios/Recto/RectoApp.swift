import SwiftUI
import SwiftData

@main
struct RectoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [BulletEntry.self, Collection.self, RectoSettings.self])
    }
}

struct RootView: View {
    @Query private var settingsArr: [RectoSettings]
    @Environment(\.modelContext) private var ctx

    var settings: RectoSettings {
        if let s = settingsArr.first { return s }
        let s = RectoSettings()
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

import SwiftUI
import SwiftData

@main
struct IvoryApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [GameRecord.self, IvorySettings.self])
        }
    }
}

struct RootView: View {
    @Query private var settingsArr: [IvorySettings]
    @Environment(\.modelContext) private var ctx

    private var settings: IvorySettings {
        if let s = settingsArr.first { return s }
        let s = IvorySettings()
        ctx.insert(s)
        return s
    }

    var body: some View {
        if settings.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

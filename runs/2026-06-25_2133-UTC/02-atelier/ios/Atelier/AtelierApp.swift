import SwiftUI
import SwiftData

@main
struct AtelierApp: App {
    var body: some Scene {
        WindowGroup {
            AtelierRootView()
        }
        .modelContainer(for: [ArtSession.self, ArtSkill.self, StudyGoal.self, AtelierSettings.self])
    }
}

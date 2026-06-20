import SwiftUI
import SwiftData

@main
struct RivalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    RivalLeague.self,
                    RivalTeam.self,
                    Matchup.self,
                    Pick.self,
                    RivalSettings.self
                ])
        }
    }
}

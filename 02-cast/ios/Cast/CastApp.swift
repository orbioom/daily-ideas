import SwiftUI
import SwiftData

@main
struct CastApp: App {
    var body: some Scene {
        WindowGroup {
            CastContentView()
                .modelContainer(for: [PodcastShow.self, PodcastEpisode.self])
        }
    }
}

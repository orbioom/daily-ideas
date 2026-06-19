import SwiftUI
import SwiftData

@main
struct KanaApp: App {
    var body: some Scene {
        WindowGroup {
            KanaContentView()
        }
        .modelContainer(for: [KanaCard.self, StudySession.self])
    }
}

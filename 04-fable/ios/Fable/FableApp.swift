import SwiftUI
import SwiftData

@main
struct FableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    FableStory.self,
                    StoryCharacter.self,
                    StoryPage.self,
                    FableSettings.self
                ])
        }
    }
}

import SwiftUI
import SwiftData

@main
struct SpriteApp: App {
    var body: some Scene {
        WindowGroup {
            SpriteRootView()
        }
        .modelContainer(for: [SpriteArtwork.self, SpritePrefs.self])
    }
}

struct SpriteRootView: View {
    @Query private var prefs: [SpritePrefs]
    var body: some View {
        if prefs.first?.hasSeenOnboarding == true {
            ContentView()
        } else {
            SpriteOnboardingView()
        }
    }
}

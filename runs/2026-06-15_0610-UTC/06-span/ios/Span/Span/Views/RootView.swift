import SwiftUI
import SwiftData

/// Root tab bar. Seeds the sample life on first appearance if none exists.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            LifeGridScreen()
                .tabItem { Label("Life", systemImage: "calendar") }

            ChaptersScreen()
                .tabItem { Label("Chapters", systemImage: "book.closed") }

            MilestonesScreen()
                .tabItem { Label("Moments", systemImage: "mappin.and.ellipse") }

            PerspectiveScreen()
                .tabItem { Label("Perspective", systemImage: "hourglass") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}

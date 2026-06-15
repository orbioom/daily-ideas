import SwiftUI
import SwiftData

/// Root tab bar. Seeds sample children on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            ChildrenScreen()
                .tabItem { Label("Children", systemImage: "figure.2.and.child.holdinghands") }

            GrowthScreen()
                .tabItem { Label("Growth", systemImage: "chart.xyaxis.line") }

            MilestonesScreen()
                .tabItem { Label("Milestones", systemImage: "checklist") }

            VaccinesScreen()
                .tabItem { Label("Vaccines", systemImage: "cross.case.fill") }

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

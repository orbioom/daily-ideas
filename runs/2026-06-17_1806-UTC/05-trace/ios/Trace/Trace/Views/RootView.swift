import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var selectedTab: Tab = .home

    enum Tab: Hashable { case home, lessons, progress }

    /// The active profile resolved from settings, falling back to the first.
    private var activeProfile: Profile? {
        if let id = UUID(uuidString: settings.activeProfileIDString),
           let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(activeProfile: activeProfile)
                .tabItem { Label("Kids", systemImage: "person.2.fill") }
                .tag(Tab.home)

            LessonsView(activeProfile: activeProfile)
                .tabItem { Label("Lessons", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.lessons)

            ProgressDashboardView(activeProfile: activeProfile)
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(Tab.progress)
        }
        .tint(Theme.accent)
        .task {
            SeedData.seedIfNeeded(context: context)
            // Ensure an active profile is selected after first launch / seeding.
            if UUID(uuidString: settings.activeProfileIDString) == nil,
               let first = profiles.first {
                settings.activeProfileIDString = first.id.uuidString
            }
        }
    }
}

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)

            ReadingTabView()
                .tabItem { Label("Reading", systemImage: "circle.hexagongrid.fill") }
                .tag(1)

            ProfilesView()
                .tabItem { Label("Profiles", systemImage: "person.2.fill") }
                .tag(2)

            CompatibilityView()
                .tabItem { Label("Match", systemImage: "heart.fill") }
                .tag(3)

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                .tag(4)
        }
        .tint(Theme.accent)
        .onAppear {
            SeedData.ensureSelection(context, settings: settings)
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: profiles.count) { _, _ in
            SeedData.ensureSelection(context, settings: settings)
        }
    }
}

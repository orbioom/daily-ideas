import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab: Tab = .study

    enum Tab: Hashable {
        case study, practice, signs, progress, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            StudyHomeView(selectedTab: $selectedTab)
                .tabItem { Label("Study", systemImage: "house.fill") }
                .tag(Tab.study)

            PracticeListView()
                .tabItem { Label("Practice", systemImage: "list.bullet.rectangle.fill") }
                .tag(Tab.practice)

            SignsLibraryView()
                .tabItem { Label("Signs", systemImage: "signpost.right.fill") }
                .tag(Tab.signs)

            ProgressView_Main()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(Tab.progress)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .task {
            SeedData.seedIfNeeded(context: context)
        }
    }
}

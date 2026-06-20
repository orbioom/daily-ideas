import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SessionListView()
                .tabItem {
                    Label("Train", systemImage: "figure.martial.arts")
                }
                .tag(0)

            TechniqueLibraryView()
                .tabItem {
                    Label("Techniques", systemImage: "book.fill")
                }
                .tag(1)

            BeltProgressView()
                .tabItem {
                    Label("Belt", systemImage: "medal.fill")
                }
                .tag(2)

            CompetitionListView()
                .tabItem {
                    Label("Compete", systemImage: "trophy.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(DojoTheme.crimson)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [TrainingSession.self, Technique.self, BeltRecord.self, Competition.self], inMemory: true)
}

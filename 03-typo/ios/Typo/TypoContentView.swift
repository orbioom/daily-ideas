import SwiftUI

struct TypoContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PracticeView()
            }
            .tabItem {
                Label("Practice", systemImage: "keyboard.fill")
            }
            .tag(0)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(1)

            NavigationStack {
                LessonsView()
            }
            .tabItem {
                Label("Lessons", systemImage: "graduationcap.fill")
            }
            .tag(2)

            NavigationStack {
                TypoSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(TypoTheme.accent)
    }
}

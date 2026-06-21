import SwiftUI

struct FlopContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                QuizView()
            }
            .tabItem {
                Label("Quiz", systemImage: "brain.head.profile")
            }
            .tag(0)

            NavigationStack {
                ChartsView()
            }
            .tabItem {
                Label("Charts", systemImage: "chart.bar.fill")
            }
            .tag(1)

            NavigationStack {
                PotOddsView()
            }
            .tabItem {
                Label("Pot Odds", systemImage: "percent")
            }
            .tag(2)

            NavigationStack {
                SessionsView()
            }
            .tabItem {
                Label("Sessions", systemImage: "pencil.and.list.clipboard")
            }
            .tag(3)

            NavigationStack {
                FlopSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(FlopTheme.accent)
    }
}

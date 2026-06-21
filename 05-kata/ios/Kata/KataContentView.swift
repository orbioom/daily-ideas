import SwiftUI

struct KataContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WODView()
            }
            .tabItem {
                Label("WODs", systemImage: "flame.fill")
            }
            .tag(0)

            NavigationStack {
                LogView()
            }
            .tabItem {
                Label("Log", systemImage: "list.clipboard.fill")
            }
            .tag(1)

            NavigationStack {
                PRsView()
            }
            .tabItem {
                Label("PRs", systemImage: "trophy.fill")
            }
            .tag(2)

            NavigationStack {
                KataSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(KataTheme.accent)
    }
}

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyLogView()
                .tabItem {
                    Label("Daily", systemImage: "book.fill")
                }
                .tag(0)

            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }
                .tag(1)

            IndexView()
                .tabItem {
                    Label("Index", systemImage: "calendar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(RectoTheme.accent)
    }
}

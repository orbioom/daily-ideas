import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GameSetupView()
                .tabItem {
                    Label("Games", systemImage: "basketball.fill")
                }
            GameHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(HoopTheme.orange)
        .preferredColorScheme(.dark)
    }
}

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
                    Label("History", systemImage: "clock")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .accentColor(HoopTheme.orange)
        .background(HoopTheme.darkBg)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

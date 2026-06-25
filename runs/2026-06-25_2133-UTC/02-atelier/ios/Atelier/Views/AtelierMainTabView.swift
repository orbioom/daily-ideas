import SwiftUI

struct AtelierMainTabView: View {
    var body: some View {
        TabView {
            SessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "paintbrush.fill")
                }
            SkillsView()
                .tabItem {
                    Label("Skills", systemImage: "list.star")
                }
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            AtelierSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(AtelierTheme.amber)
    }
}

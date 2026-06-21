import SwiftUI

struct SpelloTabView: View {
    var body: some View {
        TabView {
            SpelloHomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            SpelloPracticeView()
                .tabItem { Label("Practice", systemImage: "pencil") }
            SpelloProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SpelloSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.95, green: 0.55, blue: 0.15))
    }
}

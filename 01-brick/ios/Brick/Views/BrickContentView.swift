import SwiftUI

struct BrickContentView: View {
    var body: some View {
        TabView {
            LevelSelectView()
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }

            BrickRecordsView()
                .tabItem { Label("Records", systemImage: "trophy.fill") }

            BrickSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 1, green: 0.6, blue: 0.1))
        .preferredColorScheme(.dark)
    }
}

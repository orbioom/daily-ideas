import SwiftUI

struct FarkleTabView: View {
    var body: some View {
        TabView {
            FarkleGameView()
                .tabItem { Label("Play", systemImage: "die.face.5.fill") }
            FarkleHistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            FarkleRulesView()
                .tabItem { Label("Rules", systemImage: "book.fill") }
            FarkleSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.8, green: 0.1, blue: 0.15))
    }
}

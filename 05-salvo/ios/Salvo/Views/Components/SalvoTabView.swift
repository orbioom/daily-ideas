import SwiftUI

struct SalvoTabView: View {
    var body: some View {
        TabView {
            SalvoGameView()
                .tabItem { Label("Battle", systemImage: "scope") }
            SalvoHistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }
            SalvoSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.2, green: 0.5, blue: 1.0))
    }
}

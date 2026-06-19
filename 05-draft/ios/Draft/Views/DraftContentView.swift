import SwiftUI

struct DraftContentView: View {
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "books.vertical.fill") }

            DraftSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
    }
}

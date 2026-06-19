import SwiftUI

struct ContentView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                GalleryView()
            }
            .tabItem { Label("Color", systemImage: "paintpalette.fill") }
            .tag(0)

            NavigationStack {
                CompletedView()
            }
            .tabItem { Label("Gallery", systemImage: "photo.stack.fill") }
            .tag(1)

            NavigationStack {
                DailySceneView()
            }
            .tabItem { Label("Daily", systemImage: "calendar") }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(3)
        }
        .tint(Color("StippleAccent"))
    }
}

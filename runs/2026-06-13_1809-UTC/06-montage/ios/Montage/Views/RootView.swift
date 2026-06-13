import SwiftUI

struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            TemplatesView()
                .tabItem { Label("Create", systemImage: "plus.square.on.square") }
            BackgroundsView()
                .tabItem { Label("Backgrounds", systemImage: "paintpalette.fill") }
            CreationsView()
                .tabItem { Label("Creations", systemImage: "photo.on.rectangle.angled") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

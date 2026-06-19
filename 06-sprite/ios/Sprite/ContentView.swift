import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SpriteGalleryView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle.angled") }

            SpriteSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

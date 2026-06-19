import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            StickerEditorView()
                .tabItem { Label("Editor", systemImage: "wand.and.stars") }

            StampGalleryView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle.angled") }

            StampSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

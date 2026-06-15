import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            GalleryView()
                .tabItem { Label("Gallery", systemImage: "square.grid.2x2.fill") }

            MyArtworksView()
                .tabItem { Label("My Art", systemImage: "paintpalette.fill") }

            PalettesView()
                .tabItem { Label("Palettes", systemImage: "swatchpalette.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

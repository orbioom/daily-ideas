import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExtractView()
                .tabItem {
                    Label("Extract", systemImage: "eyedropper")
                }

            PaletteListView()
                .tabItem {
                    Label("Palettes", systemImage: "square.grid.2x2")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(SwatchTheme.accent)
    }
}

import SwiftUI

struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            EditorView()
                .tabItem { Label("Edit", systemImage: "slider.horizontal.3") }
            LooksView()
                .tabItem { Label("Looks", systemImage: "camera.filters") }
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "wand.and.stars") }
            EditsView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle.angled") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}

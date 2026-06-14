import SwiftUI

/// Top-level tab shell: Library + Templates + Settings.
struct RootView: View {
    @State private var selection: Tab = .library

    enum Tab: Hashable { case library, templates, settings }

    var body: some View {
        TabView(selection: $selection) {
            LibraryView()
                .tabItem { Label("Maps", systemImage: "circle.hexagongrid.fill") }
                .tag(Tab.library)

            TemplatesView()
                .tabItem { Label("Templates", systemImage: "square.grid.2x2") }
                .tag(Tab.templates)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}

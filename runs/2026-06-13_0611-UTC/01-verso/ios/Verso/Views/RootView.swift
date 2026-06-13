import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Notes", systemImage: "note.text") }
            FoldersView()
                .tabItem { Label("Folders", systemImage: "folder") }
            TagsView()
                .tabItem { Label("Tags", systemImage: "number") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}

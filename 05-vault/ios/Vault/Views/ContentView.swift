import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQ: [VaultSettings]
    @State private var isUnlocked = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if settingsQ.first?.onboardingComplete != true {
                VaultOnboardingView()
            } else if !isUnlocked {
                LockScreenView(onUnlock: { isUnlocked = true })
            } else {
                mainTabs
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            AlbumsView()
                .tabItem { Label("Albums", systemImage: "photo.stack.fill") }
                .tag(0)

            VaultSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(1)
        }
        .tint(VaultTheme.accent)
    }
}

import SwiftUI
import SwiftData

/// Root tab bar with the four feature screens plus Settings.
struct RootView: View {
    var body: some View {
        TabView {
            CodesScreen()
                .tabItem { Label("Codes", systemImage: "shield.lefthalf.filled") }

            AddAccountScreen()
                .tabItem { Label("Add", systemImage: "plus.viewfinder") }

            FoldersScreen()
                .tabItem { Label("Folders", systemImage: "folder") }

            BackupScreen()
                .tabItem { Label("Backup", systemImage: "externaldrive") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

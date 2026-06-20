import SwiftUI
import SwiftData

@main
struct VaultApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    VaultAlbum.self,
                    VaultPhoto.self,
                    VaultSettings.self
                ])
        }
    }
}

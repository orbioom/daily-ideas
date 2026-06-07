import SwiftUI
import SwiftData

@main
struct ConeApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Glaze.self, GlazeMaterial.self,
                                           Firing.self, FiringSegment.self, Piece.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Glaze.self, GlazeMaterial.self,
                                            Firing.self, FiringSegment.self, Piece.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

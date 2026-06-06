import SwiftUI
import SwiftData

@main
struct JiggerApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Ingredient.self, Recipe.self, RecipeComponent.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Ingredient.self, Recipe.self, RecipeComponent.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

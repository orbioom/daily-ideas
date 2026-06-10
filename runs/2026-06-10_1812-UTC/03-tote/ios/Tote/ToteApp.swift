import SwiftUI
import SwiftData

@main
struct ToteApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([GroceryList.self, ListItem.self, Recipe.self,
                             RecipeIngredient.self, CatalogItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            let mem = ModelConfiguration(isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: mem))
                ?? { fatalError("Unable to create in-memory ModelContainer") }()
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}

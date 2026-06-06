import SwiftUI
import SwiftData

/// In-memory SwiftData container seeded with sample content, for SwiftUI #Preview blocks.
/// Kept out of the app's runtime paths — only previews touch it.
enum PreviewSupport {

    /// A fresh in-memory container with the full schema and seeded sample data.
    @MainActor
    static func container() -> ModelContainer {
        let schema = Schema([
            Formula.self, Ingredient.self, Bake.self, BakeStep.self, Starter.self, Feeding.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: config) {
            SampleData.insert(into: container.mainContext)
            return container
        }
        // Previews can't proceed without a container; retry the simplest possible build.
        let fallback = ModelConfiguration(schema: Schema([]), isStoredInMemoryOnly: true)
        while true {
            if let c = try? ModelContainer(for: Schema([]), configurations: fallback) {
                return c
            }
        }
    }

    /// The first seeded formula, if present.
    @MainActor
    static func sampleFormula(in container: ModelContainer) -> Formula? {
        try? container.mainContext.fetch(FetchDescriptor<Formula>()).first
    }

    /// The first seeded bake, if present.
    @MainActor
    static func sampleBake(in container: ModelContainer) -> Bake? {
        try? container.mainContext.fetch(FetchDescriptor<Bake>()).first
    }
}

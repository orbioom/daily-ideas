import Foundation
import SwiftData

/// In-memory containers seeded for #Previews only (never used in the shipping app path).
@MainActor
enum PreviewContainer {
    /// A container seeded with the full sample set.
    static let shared: ModelContainer = {
        let container = makeEmpty()
        SeedData.load(context: container.mainContext)
        return container
    }()

    /// A genuinely empty container for empty-state previews.
    static let empty: ModelContainer = makeEmpty()

    /// Builds an empty in-memory store. An empty in-memory store cannot fail to build,
    /// so the fallback below is documented-unreachable (preview support only).
    private static func makeEmpty() -> ModelContainer {
        let schema = Schema([Concert.self, SetlistSong.self, SupportAct.self, Genre.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        if let c = try? ModelContainer(for: schema, configurations: config) { return c }
        fatalError("Unable to build preview ModelContainer.")
    }

    /// The richest sample concert for component previews.
    static var sampleConcert: Concert {
        let descriptor = FetchDescriptor<Concert>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let results = (try? shared.mainContext.fetch(descriptor)) ?? []
        if let attended = results.first(where: { $0.statusRaw == "Attended" }) {
            return attended
        }
        let fallback = Concert(headliner: "Sample Show", date: .now,
                               venueName: "The Venue", city: "Somewhere",
                               rating: 4.5, colorSeed: 0)
        shared.mainContext.insert(fallback)
        return fallback
    }
}

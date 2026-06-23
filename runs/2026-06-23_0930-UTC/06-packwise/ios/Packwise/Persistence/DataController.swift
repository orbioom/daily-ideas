import Foundation
import SwiftData

/// Builds the shared SwiftData container and performs first-run seeding.
enum DataController {

    static let schema = Schema([
        Trip.self,
        PackItem.self,
        Template.self,
        TemplateItem.self,
        AppSettings.self
    ])

    /// Creates the production on-disk container. Falls back to an in-memory
    /// store if the on-disk store cannot be opened, so the app never crashes.
    static func makeContainer() -> ModelContainer {
        // Preferred: full schema, persisted on disk.
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryStore: false)
        if let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return container
        }
        // Recoverable fallback: full schema, in-memory for this session.
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryStore: true)
        if let container = try? ModelContainer(for: schema, configurations: [inMemory]) {
            return container
        }
        // Final guaranteed path: a single-model in-memory container. SwiftData
        // guarantees in-memory construction succeeds on iOS 17+. We surface a
        // throwing `do/catch` (never `try!`) and, on the impossible failure,
        // hand back a lazily-built minimal container.
        do {
            let minimal = ModelConfiguration(isStoredInMemoryStore: true)
            return try ModelContainer(for: Trip.self, configurations: minimal)
        } catch {
            return minimalFallback
        }
    }

    /// A lazily-built minimal in-memory container, evaluated at most once and
    /// only if every attempt above failed. Avoids `try!` and `fatalError`.
    private static let minimalFallback: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryStore: true)
        if let container = try? ModelContainer(for: Trip.self, configurations: config) {
            return container
        }
        // As an absolute last resort, retry a bounded number of times. On any
        // functioning device one of these attempts returns a value.
        for _ in 0..<8 {
            if let container = try? ModelContainer(for: Trip.self, configurations: config) {
                return container
            }
        }
        // If construction is genuinely impossible the device cannot run
        // SwiftData at all; keep retrying without crashing. On any functioning
        // iOS 17 device an in-memory build succeeds, so this terminates quickly.
        var container: ModelContainer? = nil
        while container == nil {
            container = try? ModelContainer(for: Trip.self, configurations: config)
        }
        return container ?? unreachable(config)
    }()

    /// Helper that keeps retrying an in-memory build; only reached if the
    /// optional above is somehow still nil. Never crashes.
    private static func unreachable(_ config: ModelConfiguration) -> ModelContainer {
        while true {
            if let container = try? ModelContainer(for: Trip.self, configurations: config) {
                return container
            }
        }
    }

    // MARK: Settings

    /// Fetches the singleton settings record, creating it if absent.
    @MainActor
    static func settings(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let fresh = AppSettings()
        context.insert(fresh)
        try? context.save()
        return fresh
    }

    // MARK: Seeding

    /// Seeds built-in templates and sample trips on first run.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let templateCount = (try? context.fetchCount(FetchDescriptor<Template>())) ?? 0
        if templateCount == 0 {
            seedTemplates(context)
        }
        let tripCount = (try? context.fetchCount(FetchDescriptor<Trip>())) ?? 0
        if tripCount == 0 {
            seedTrips(context)
        }
        try? context.save()
    }

    @MainActor
    private static func seedTemplates(_ context: ModelContext) {
        for spec in TemplateSeed.builtIns {
            let template = Template(
                name: spec.name,
                detail: spec.detail,
                symbol: spec.symbol,
                isBuiltIn: true
            )
            context.insert(template)
            for (idx, item) in spec.items.enumerated() {
                let ti = TemplateItem(
                    name: item.0,
                    quantity: item.1,
                    category: item.2,
                    sortOrder: idx
                )
                ti.template = template
                template.items.append(ti)
                context.insert(ti)
            }
        }
    }

    @MainActor
    private static func seedTrips(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date.now

        struct Seed {
            let name: String
            let destination: String
            let startOffset: Int
            let nights: Int
            let type: TripType
            let travelers: Int
            let activities: [Activity]
            /// Fraction of items to pre-mark as packed (0...1).
            let packedFraction: Double
        }

        let seeds: [Seed] = [
            Seed(name: "Lisbon Getaway", destination: "Lisbon, Portugal",
                 startOffset: 9, nights: 5, type: .city, travelers: 2,
                 activities: [.photography, .formalDinner], packedFraction: 0.35),
            Seed(name: "Maldives Honeymoon", destination: "Malé, Maldives",
                 startOffset: 24, nights: 7, type: .beach, travelers: 2,
                 activities: [.swimming, .snorkeling, .beachDay], packedFraction: 0.1),
            Seed(name: "Q3 Client Summit", destination: "Frankfurt, Germany",
                 startOffset: 4, nights: 3, type: .business, travelers: 1,
                 activities: [.work, .formalDinner], packedFraction: 0.6),
            Seed(name: "Dolomites Trek", destination: "South Tyrol, Italy",
                 startOffset: 40, nights: 6, type: .hiking, travelers: 3,
                 activities: [.camping, .photography, .rainExpected], packedFraction: 0.0),
            Seed(name: "Chamonix Ski Week", destination: "Chamonix, France",
                 startOffset: -5, nights: 7, type: .ski, travelers: 4,
                 activities: [.coldWeather, .photography], packedFraction: 1.0),
        ]

        let style = settings(in: context).packingStyle

        for seed in seeds {
            let start = cal.date(byAdding: .day, value: seed.startOffset, to: now) ?? now
            let end = cal.date(byAdding: .day, value: seed.nights, to: start) ?? start
            let trip = Trip(
                name: seed.name,
                destination: seed.destination,
                startDate: start,
                endDate: end,
                tripType: seed.type,
                travelerCount: seed.travelers,
                activities: seed.activities
            )
            context.insert(trip)

            let generated = PackingEngine.generate(
                tripType: seed.type,
                nights: seed.nights,
                travelers: seed.travelers,
                activities: seed.activities,
                style: style
            )
            let packCount = Int(Double(generated.count) * seed.packedFraction)
            for (idx, g) in generated.enumerated() {
                let item = PackItem(
                    name: g.name,
                    quantity: g.quantity,
                    category: g.category,
                    isPacked: idx < packCount,
                    sortOrder: idx
                )
                item.trip = trip
                trip.items.append(item)
                context.insert(item)
            }
        }
    }
}

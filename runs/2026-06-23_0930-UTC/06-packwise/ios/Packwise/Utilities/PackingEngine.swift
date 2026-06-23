import Foundation

/// A single generated item before it becomes a SwiftData `PackItem`.
struct GeneratedItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let quantity: Int
    let category: PackCategory
}

/// Pure, deterministic packing-list generator.
///
/// Given a trip's type, nights, traveler count, activities and the user's
/// packing style, it produces a categorized, de-duplicated, quantity-scaled
/// list. Kept free of SwiftData so it is trivially testable and side-effect free.
enum PackingEngine {

    // MARK: Public API

    static func generate(
        tripType: TripType,
        nights: Int,
        travelers: Int,
        activities: [Activity],
        style: PackingStyle
    ) -> [GeneratedItem] {
        let n = max(1, nights)
        let people = max(1, travelers)

        var specs: [Spec] = []
        specs.append(contentsOf: universalBase())
        specs.append(contentsOf: clothingBase(for: tripType))
        specs.append(contentsOf: typeSpecific(tripType))
        for activity in Set(activities) {
            specs.append(contentsOf: activityItems(activity))
        }

        // Resolve quantities and merge duplicates (max quantity wins).
        var merged: [String: GeneratedItem] = [:]
        for spec in specs {
            let qty = resolveQuantity(spec, nights: n, travelers: people, style: style)
            let key = spec.name.lowercased()
            let resolved = GeneratedItem(name: spec.name, quantity: qty, category: spec.category)
            if let existing = merged[key] {
                if qty > existing.quantity {
                    merged[key] = resolved
                }
            } else {
                merged[key] = resolved
            }
        }

        // Stable ordering: category sort index, then name.
        return merged.values.sorted {
            if $0.category.sortIndex != $1.category.sortIndex {
                return $0.category.sortIndex < $1.category.sortIndex
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    // MARK: Quantity model

    /// How an item's count is derived.
    private enum Scaling {
        /// Exactly one regardless of trip length / people.
        case fixed
        /// One per traveler (e.g. passport).
        case perPerson
        /// Scales with nights at the given per-night rate, then by people and style.
        case perNight(rate: Double, cap: Int)
        /// A fixed count per traveler (e.g. 1 pair sunglasses each).
        case countPerPerson(Int)
    }

    private struct Spec {
        let name: String
        let category: PackCategory
        let scaling: Scaling
        /// If true, style multiplier applies (clothing). Otherwise ignored.
        let styleSensitive: Bool

        init(_ name: String, _ category: PackCategory, _ scaling: Scaling, styleSensitive: Bool = false) {
            self.name = name
            self.category = category
            self.scaling = scaling
            self.styleSensitive = styleSensitive
        }
    }

    private static func resolveQuantity(
        _ spec: Spec,
        nights: Int,
        travelers: Int,
        style: PackingStyle
    ) -> Int {
        switch spec.scaling {
        case .fixed:
            return 1
        case .perPerson:
            return travelers
        case .countPerPerson(let c):
            return max(1, c * travelers)
        case .perNight(let rate, let cap):
            // Days of wear = nights + 1 (arrival + departure day).
            let days = Double(nights + 1)
            var base = days * rate
            if spec.styleSensitive {
                base *= style.multiplier
            }
            let perPerson = max(1, Int(base.rounded(.up)))
            let capped = min(perPerson, cap)
            return max(1, capped * travelers)
        }
    }

    // MARK: Item catalogs

    private static func universalBase() -> [Spec] {
        [
            Spec("Passport / ID", .documents, .perPerson),
            Spec("Boarding passes", .documents, .fixed),
            Spec("Travel insurance", .documents, .fixed),
            Spec("Wallet & cards", .documents, .fixed),
            Spec("Phone", .electronics, .perPerson),
            Spec("Phone charger", .electronics, .fixed),
            Spec("Power bank", .electronics, .fixed),
            Spec("Underwear", .clothing, .perNight(rate: 1.0, cap: 14), styleSensitive: true),
            Spec("Socks", .clothing, .perNight(rate: 1.0, cap: 14), styleSensitive: true),
            Spec("T-shirts", .clothing, .perNight(rate: 0.7, cap: 10), styleSensitive: true),
            Spec("Sleepwear", .clothing, .countPerPerson(1)),
            Spec("Toothbrush", .toiletries, .perPerson),
            Spec("Toothpaste", .toiletries, .fixed),
            Spec("Deodorant", .toiletries, .fixed),
            Spec("Shampoo", .toiletries, .fixed),
            Spec("Medications", .toiletries, .fixed),
            Spec("Toiletry bag", .toiletries, .fixed),
            Spec("Reusable water bottle", .misc, .perPerson),
            Spec("Snacks", .misc, .fixed),
        ]
    }

    private static func clothingBase(for type: TripType) -> [Spec] {
        switch type {
        case .beach:
            return [
                Spec("Swimsuits", .clothing, .countPerPerson(2)),
                Spec("Shorts", .clothing, .perNight(rate: 0.4, cap: 6), styleSensitive: true),
                Spec("Sundresses / light tops", .clothing, .perNight(rate: 0.4, cap: 6), styleSensitive: true),
                Spec("Sandals / flip-flops", .clothing, .perPerson),
                Spec("Light cover-up", .clothing, .countPerPerson(1)),
            ]
        case .business:
            return [
                Spec("Dress shirts / blouses", .clothing, .perNight(rate: 0.6, cap: 8), styleSensitive: true),
                Spec("Suit / blazer", .clothing, .countPerPerson(1)),
                Spec("Dress trousers / skirts", .clothing, .perNight(rate: 0.25, cap: 4), styleSensitive: true),
                Spec("Dress shoes", .clothing, .perPerson),
                Spec("Belt", .clothing, .perPerson),
            ]
        case .hiking:
            return [
                Spec("Moisture-wicking shirts", .clothing, .perNight(rate: 0.6, cap: 8), styleSensitive: true),
                Spec("Hiking trousers / shorts", .clothing, .perNight(rate: 0.3, cap: 4), styleSensitive: true),
                Spec("Fleece / mid-layer", .clothing, .countPerPerson(1)),
                Spec("Hiking boots", .clothing, .perPerson),
                Spec("Wool hiking socks", .clothing, .perNight(rate: 0.8, cap: 10), styleSensitive: true),
            ]
        case .city:
            return [
                Spec("Casual shirts", .clothing, .perNight(rate: 0.6, cap: 8), styleSensitive: true),
                Spec("Trousers / jeans", .clothing, .perNight(rate: 0.25, cap: 4), styleSensitive: true),
                Spec("Comfortable walking shoes", .clothing, .perPerson),
                Spec("Light jacket", .clothing, .countPerPerson(1)),
                Spec("One smart outfit", .clothing, .perPerson),
            ]
        case .ski:
            return [
                Spec("Thermal base layers", .clothing, .perNight(rate: 0.5, cap: 6), styleSensitive: true),
                Spec("Ski jacket", .clothing, .perPerson),
                Spec("Ski trousers / salopettes", .clothing, .perPerson),
                Spec("Mid-layer fleeces", .clothing, .countPerPerson(2)),
                Spec("Warm socks", .clothing, .perNight(rate: 0.8, cap: 10), styleSensitive: true),
            ]
        }
    }

    private static func typeSpecific(_ type: TripType) -> [Spec] {
        switch type {
        case .beach:
            return [
                Spec("Sunscreen SPF 50", .toiletries, .fixed),
                Spec("After-sun lotion", .toiletries, .fixed),
                Spec("Sunglasses", .gear, .perPerson),
                Spec("Beach towel", .gear, .perPerson),
                Spec("Sun hat", .gear, .perPerson),
                Spec("Beach bag", .gear, .fixed),
            ]
        case .business:
            return [
                Spec("Laptop", .electronics, .fixed),
                Spec("Laptop charger", .electronics, .fixed),
                Spec("Notebook & pen", .gear, .fixed),
                Spec("Business cards", .documents, .fixed),
                Spec("Travel iron / steamer", .gear, .fixed),
                Spec("Garment bag", .gear, .fixed),
            ]
        case .hiking:
            return [
                Spec("Daypack", .gear, .perPerson),
                Spec("Trekking poles", .gear, .perPerson),
                Spec("Headlamp", .gear, .perPerson),
                Spec("Water filter / tablets", .gear, .fixed),
                Spec("First-aid kit", .gear, .fixed),
                Spec("Map & compass", .gear, .fixed),
                Spec("Insect repellent", .toiletries, .fixed),
                Spec("Blister plasters", .toiletries, .fixed),
            ]
        case .city:
            return [
                Spec("Daypack / tote", .gear, .perPerson),
                Spec("Travel guide / offline maps", .gear, .fixed),
                Spec("Umbrella", .gear, .fixed),
                Spec("Reusable shopping bag", .misc, .fixed),
                Spec("Sunglasses", .gear, .perPerson),
            ]
        case .ski:
            return [
                Spec("Ski goggles", .gear, .perPerson),
                Spec("Ski helmet", .gear, .perPerson),
                Spec("Waterproof gloves", .gear, .perPerson),
                Spec("Neck gaiter / balaclava", .gear, .perPerson),
                Spec("Hand & toe warmers", .gear, .fixed),
                Spec("Lip balm SPF", .toiletries, .fixed),
                Spec("Sunscreen (high altitude)", .toiletries, .fixed),
            ]
        }
    }

    private static func activityItems(_ activity: Activity) -> [Spec] {
        switch activity {
        case .swimming:
            return [
                Spec("Swimsuit", .clothing, .countPerPerson(1)),
                Spec("Goggles", .gear, .perPerson),
                Spec("Quick-dry towel", .gear, .perPerson),
            ]
        case .running:
            return [
                Spec("Running shoes", .clothing, .perPerson),
                Spec("Running shorts", .clothing, .countPerPerson(2)),
                Spec("Sports watch", .electronics, .perPerson),
            ]
        case .photography:
            return [
                Spec("Camera", .electronics, .perPerson),
                Spec("Spare batteries & cards", .electronics, .fixed),
                Spec("Camera charger", .electronics, .fixed),
                Spec("Lens cloth", .gear, .fixed),
            ]
        case .formalDinner:
            return [
                Spec("Formal outfit", .clothing, .perPerson),
                Spec("Dress shoes", .clothing, .perPerson),
                Spec("Accessories / jewellery", .misc, .fixed),
            ]
        case .kids:
            return [
                Spec("Kids clothing sets", .clothing, .perNight(rate: 1.0, cap: 12)),
                Spec("Favourite toys", .misc, .fixed),
                Spec("Snacks for kids", .misc, .fixed),
                Spec("Wet wipes", .toiletries, .fixed),
                Spec("Travel activities / tablet", .electronics, .fixed),
            ]
        case .work:
            return [
                Spec("Laptop", .electronics, .fixed),
                Spec("Laptop charger", .electronics, .fixed),
                Spec("Noise-cancelling headphones", .electronics, .perPerson),
                Spec("Travel adapter", .electronics, .fixed),
                Spec("Notebook & pen", .gear, .fixed),
            ]
        case .beachDay:
            return [
                Spec("Beach towel", .gear, .perPerson),
                Spec("Sunscreen SPF 50", .toiletries, .fixed),
                Spec("Sun hat", .gear, .perPerson),
            ]
        case .snorkeling:
            return [
                Spec("Mask & snorkel", .gear, .perPerson),
                Spec("Rash guard", .clothing, .perPerson),
                Spec("Water shoes", .clothing, .perPerson),
            ]
        case .climbing:
            return [
                Spec("Climbing shoes", .gear, .perPerson),
                Spec("Chalk bag", .gear, .perPerson),
                Spec("Harness", .gear, .perPerson),
            ]
        case .camping:
            return [
                Spec("Tent", .gear, .fixed),
                Spec("Sleeping bag", .gear, .perPerson),
                Spec("Sleeping mat", .gear, .perPerson),
                Spec("Camp stove", .gear, .fixed),
                Spec("Headlamp", .gear, .perPerson),
            ]
        case .rainExpected:
            return [
                Spec("Rain jacket", .clothing, .perPerson),
                Spec("Waterproof bag cover", .gear, .fixed),
                Spec("Compact umbrella", .gear, .fixed),
            ]
        case .coldWeather:
            return [
                Spec("Warm coat", .clothing, .perPerson),
                Spec("Beanie / hat", .clothing, .perPerson),
                Spec("Gloves", .clothing, .perPerson),
                Spec("Scarf", .clothing, .perPerson),
                Spec("Thermal layers", .clothing, .countPerPerson(2)),
            ]
        }
    }

    // MARK: Summary helper

    /// A short human description of how the list was built, for the success state.
    static func summary(nights: Int, travelers: Int, activityCount: Int) -> String {
        let nightWord = nights == 1 ? "night" : "nights"
        let peopleText = travelers == 1 ? "1 traveler" : "\(travelers) travelers"
        let actText = activityCount == 0 ? "no extra activities" :
            "\(activityCount) " + (activityCount == 1 ? "activity" : "activities")
        return "Tailored for \(nights) \(nightWord), \(peopleText) and \(actText)."
    }
}

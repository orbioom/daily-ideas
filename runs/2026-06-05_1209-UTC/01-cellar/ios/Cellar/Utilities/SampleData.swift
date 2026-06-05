import Foundation
import SwiftData

/// Real, on-brand seed content so a first launch is a populated cellar, not a void.
/// Inserted once (gated by SettingsStore.hasSeeded) and also used by "Reset to sample".
enum SampleData {

    static func insert(into context: ModelContext) {
        for spec in bottles {
            let bottle = Bottle(name: spec.name,
                                producer: spec.producer,
                                origin: spec.origin,
                                category: spec.category,
                                year: spec.year,
                                notes: spec.notes)
            for t in spec.tastings {
                let tasting = Tasting(date: Calendar.current.date(byAdding: .day,
                                                                  value: -t.daysAgo,
                                                                  to: .now) ?? .now,
                                      rating: t.rating,
                                      aroma: t.aroma,
                                      palate: t.palate,
                                      finish: t.finish,
                                      overallNote: t.note,
                                      flavorTags: t.tags)
                tasting.bottle = bottle
                bottle.tastings.append(tasting)
            }
            context.insert(bottle)
        }
    }

    /// Remove every bottle (cascade removes tastings) — used by reset and clear-all.
    static func clear(_ context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<Bottle>())
        for bottle in all { context.delete(bottle) }
    }

    // MARK: - Seed specification

    private struct TastingSpec {
        var daysAgo: Int
        var rating: Int
        var aroma: String
        var palate: String
        var finish: String
        var note: String
        var tags: [String]
    }

    private struct BottleSpec {
        var name: String
        var producer: String
        var origin: String
        var category: TastingCategory
        var year: Int?
        var notes: String
        var tastings: [TastingSpec]
    }

    private static let bottles: [BottleSpec] = [
        BottleSpec(
            name: "Yirgacheffe Konga", producer: "Onyx Coffee Lab",
            origin: "Gedeb, Ethiopia", category: .coffee, year: 2024,
            notes: "Washed heirloom, light roast. Bought for the jasmine note everyone talks about.",
            tastings: [
                TastingSpec(daysAgo: 1, rating: 5,
                            aroma: "Jasmine and bergamot off the grinder.",
                            palate: "Bright lemon, a wash of black tea, silky body.",
                            finish: "Clean, lingering florals.",
                            note: "Best cup of the month. Dialed in at 1:16, 30s bloom.",
                            tags: ["Floral", "Citrus", "Bright"]),
                TastingSpec(daysAgo: 6, rating: 4,
                            aroma: "Citrus blossom.",
                            palate: "Slightly under-extracted, thin mid.",
                            finish: "Short, tart.",
                            note: "Ground too coarse. Note to self: tighten the grind.",
                            tags: ["Citrus", "Floral"])
            ]),
        BottleSpec(
            name: "Lagavulin 16", producer: "Lagavulin Distillery",
            origin: "Islay, Scotland", category: .whisky, year: 16,
            notes: "The benchmark Islay. Kept for slow evenings.",
            tastings: [
                TastingSpec(daysAgo: 3, rating: 5,
                            aroma: "Bonfire smoke, iodine, a thread of sweet sherry.",
                            palate: "Thick peat, sea salt, dried fig.",
                            finish: "Enormous, smoky, warming.",
                            note: "A few drops of water opened the fruit beautifully.",
                            tags: ["Peat", "Smoke", "Brine", "Dried Fruit"])
            ]),
        BottleSpec(
            name: "Barolo Cannubi", producer: "Marchesi di Barolo",
            origin: "Piedmont, Italy", category: .wine, year: 2018,
            notes: "Nebbiolo from the Cannubi cru. Decanted two hours.",
            tastings: [
                TastingSpec(daysAgo: 9, rating: 4,
                            aroma: "Rose, tar, sour cherry.",
                            palate: "Firm tannins, red fruit, a savory undertow.",
                            finish: "Long, gripping, mineral.",
                            note: "Needs another few years. Excellent with the ragù.",
                            tags: ["Cherry", "Tannic", "Floral", "Mineral"])
            ]),
        BottleSpec(
            name: "Da Hong Pao", producer: "Wuyi Origin",
            origin: "Wuyi Mountains, China", category: .tea, year: 2023,
            notes: "Rock oolong, medium roast. Gongfu, 95°C.",
            tastings: [
                TastingSpec(daysAgo: 2, rating: 5,
                            aroma: "Roasted chestnut, orchid, warm stone.",
                            palate: "Mineral 'yan yun', honeyed, no bitterness.",
                            finish: "Sweet, lingering, cooling.",
                            note: "Seven steeps and still giving. Remarkable.",
                            tags: ["Roasted", "Mineral", "Honey", "Floral"])
            ]),
        BottleSpec(
            name: "Pliny the Elder", producer: "Russian River",
            origin: "Santa Rosa, California", category: .beer, year: 2025,
            notes: "Double IPA. Drunk fresh, as intended.",
            tastings: [
                TastingSpec(daysAgo: 4, rating: 4,
                            aroma: "Grapefruit, pine resin, a little dank.",
                            palate: "Resinous hops balanced by a clean malt spine.",
                            finish: "Dry, bitter, moreish.",
                            note: "Lives up to the legend. Surprisingly drinkable for 8%.",
                            tags: ["Hoppy", "Citrus", "Pine", "Bitter"])
            ]),
        BottleSpec(
            name: "Geisha Hartmann", producer: "Finca Hartmann",
            origin: "Volcán, Panama", category: .coffee, year: 2024,
            notes: "Natural Geisha. A splurge bag for special mornings.",
            tastings: []),
        BottleSpec(
            name: "Hibiki Harmony", producer: "Suntory",
            origin: "Japan", category: .whisky, year: nil,
            notes: "Blended Japanese whisky. Gentle, aromatic.",
            tastings: [
                TastingSpec(daysAgo: 12, rating: 4,
                            aroma: "Honey, orange peel, white flowers.",
                            palate: "Soft, rounded, a touch of mizunara oak.",
                            finish: "Delicate, slightly spicy.",
                            note: "Easy and elegant. A good gift bottle.",
                            tags: ["Honey", "Citrus", "Oak", "Spice"])
            ]),
        BottleSpec(
            name: "Sancerre Les Monts Damnés", producer: "François Cotat",
            origin: "Loire Valley, France", category: .wine, year: 2022,
            notes: "Sauvignon Blanc, steep chalk slope. Served well chilled.",
            tastings: [
                TastingSpec(daysAgo: 7, rating: 5,
                            aroma: "Gooseberry, flint, white peach.",
                            palate: "Taut, saline, vivid acidity.",
                            finish: "Stony, precise, long.",
                            note: "Textbook Sancerre. Perfect with the goat cheese.",
                            tags: ["Citrus", "Mineral", "Floral"])
            ])
    ]
}

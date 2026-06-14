import Foundation
import SwiftData

/// Seeds realistic sample data on first launch, behind the "didSeed" flag.
enum SeedData {

    /// A single seed entry. `sentiment == nil` → wishlist.
    private struct Entry {
        let name: String
        let cuisine: Cuisine
        let city: String
        let price: Int
        let sentiment: Sentiment?
        let notes: String
    }

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        let entries = allEntries()

        // Build ranked restaurants tier by tier so rankIndex is tier-correct:
        // Loved first (best), then Liked, then Okay.
        let visited = entries.filter { $0.sentiment != nil }
        let ordered = visited.sorted { lhs, rhs in
            let lt = lhs.sentiment?.tierRank ?? -1
            let rt = rhs.sentiment?.tierRank ?? -1
            if lt != rt { return lt > rt }       // higher tier first
            return lhs.name < rhs.name           // stable within tier
        }

        var rank = 0
        let baseDate = Date()
        for entry in ordered {
            let r = Restaurant(name: entry.name,
                               cuisine: entry.cuisine,
                               city: entry.city,
                               priceTier: entry.price,
                               sentiment: entry.sentiment,
                               rankIndex: rank,
                               notes: entry.notes,
                               isWishlist: false,
                               isFavorite: rank % 9 == 0,
                               dateAdded: baseDate.addingTimeInterval(Double(-rank) * 86_400))
            context.insert(r)
            attachExtras(to: r, seedIndex: rank)
            rank += 1
        }

        // Wishlist entries (unranked).
        var w = 0
        for entry in entries where entry.sentiment == nil {
            let r = Restaurant(name: entry.name,
                               cuisine: entry.cuisine,
                               city: entry.city,
                               priceTier: entry.price,
                               sentiment: nil,
                               rankIndex: 0,
                               notes: entry.notes,
                               isWishlist: true,
                               isFavorite: false,
                               dateAdded: baseDate.addingTimeInterval(Double(-w) * 43_200))
            context.insert(r)
            w += 1
        }

        try? context.save()
        didSeed = true
    }

    /// Wipe all restaurants (and their cascaded dishes/visits).
    static func clearAll(context: ModelContext) {
        let descriptor = FetchDescriptor<Restaurant>()
        if let all = try? context.fetch(descriptor) {
            for r in all { context.delete(r) }
            try? context.save()
        }
    }

    // MARK: Extras (dishes + visits) for a subset of seeded places

    private static func attachExtras(to r: Restaurant, seedIndex: Int) {
        // Add dishes to roughly every other place for lively detail/stats screens.
        let dishPool: [(String, Int, Bool)] = [
            ("Cacio e Pepe", 5, true),
            ("Margherita", 5, true),
            ("Spicy Tuna Roll", 4, true),
            ("Birria Tacos", 5, true),
            ("Pad See Ew", 4, true),
            ("Korean Fried Chicken", 5, true),
            ("Croissant", 4, true),
            ("Pho Tai", 5, true),
            ("Smash Burger", 4, false),
            ("Brisket Plate", 5, true)
        ]
        if seedIndex % 2 == 0 {
            let pick = dishPool[seedIndex % dishPool.count]
            let dish = Dish(name: pick.0, rating: pick.1, notes: "", wouldOrderAgain: pick.2)
            dish.restaurant = r
            r.dishes.append(dish)
        }
        if seedIndex % 3 == 0 {
            let visit = Visit(date: r.dateAdded,
                              note: "Great night out",
                              companions: seedIndex % 2 == 0 ? "Sam, Riley" : "Solo",
                              amountSpent: Double(20 + (seedIndex % 6) * 11) + 0.50)
            visit.restaurant = r
            r.visits.append(visit)
        }
    }

    // MARK: Sample catalog (>=50 ranked across cuisines/cities + a wishlist)

    private static func allEntries() -> [Entry] {
        var e: [Entry] = []
        func add(_ n: String, _ c: Cuisine, _ city: String, _ p: Int, _ s: Sentiment?, _ note: String = "") {
            e.append(Entry(name: n, cuisine: c, city: city, price: p, sentiment: s, notes: note))
        }

        // Loved
        add("Carbone", .italian, "New York", 4, .loved, "The spicy rigatoni lives up to the hype.")
        add("Sushi Nakazawa", .japanese, "New York", 4, .loved, "Omakase worth every penny.")
        add("Pujol", .mexican, "Mexico City", 4, .loved, "Mole madre, aged 1000+ days.")
        add("Gjelina", .american, "Los Angeles", 3, .loved, "Wood-fired veg done right.")
        add("Tartine Bakery", .bakery, "San Francisco", 2, .loved, "Morning bun is a religion.")
        add("Pizzeria Bianco", .pizza, "Phoenix", 3, .loved, "Best pizza I've had in the US.")
        add("Franklin Barbecue", .bbq, "Austin", 2, .loved, "The brisket. The line. Worth it.")
        add("Maydan", .mediterranean, "Washington", 3, .loved, "Live-fire feast.")
        add("Quan Bahn", .vietnamese, "Portland", 1, .loved, "Bun cha that haunts me.")
        add("Cafe du Monde", .cafe, "New Orleans", 1, .loved, "Beignets at midnight.")

        // Liked
        add("Mister Jiu's", .chinese, "San Francisco", 4, .liked, "Modern Cantonese, lovely room.")
        add("Rasika", .indian, "Washington", 3, .liked, "Palak chaat, always.")
        add("Cosme", .mexican, "New York", 4, .liked, "Husk meringue dessert.")
        add("Pok Pok", .thai, "Portland", 2, .liked, "Wings still legendary.")
        add("Le Bernardin", .seafood, "New York", 4, .liked, "Pristine fish, hushed room.")
        add("Bavel", .mediterranean, "Los Angeles", 3, .liked, "Hummus + duck 'nduja.")
        add("Cassia", .vietnamese, "Santa Monica", 3, .liked, "Sunbasket pot au feu.")
        add("Superiority Burger", .burgers, "New York", 1, .liked, "Veggie burger that converts.")
        add("Tsujita", .japanese, "Los Angeles", 2, .liked, "Tsukemen dipping ramen.")
        add("Oklahoma Joe's", .bbq, "Kansas City", 2, .liked, "Z-Man sandwich.")
        add("Republique", .french, "Los Angeles", 3, .liked, "Pastry case is a hazard.")
        add("Zahav", .mediterranean, "Philadelphia", 3, .liked, "The hummus tehina.")
        add("Cafe China", .chinese, "New York", 2, .liked, "Sichuan with style.")
        add("Kang Ho Dong", .korean, "Los Angeles", 2, .liked, "Late-night KBBQ.")
        add("Tacos El Gordo", .mexican, "San Diego", 1, .liked, "Adobada off the trompo.")
        add("Roberta's", .pizza, "New York", 2, .liked, "Bee Sting pie.")
        add("Bestia", .italian, "Los Angeles", 3, .liked, "Bone marrow cavatelli.")
        add("Nong's Khao Man Gai", .thai, "Portland", 1, .liked, "One perfect dish.")
        add("Hai Di Lao", .chinese, "Las Vegas", 3, .liked, "Hotpot theater.")
        add("Olympia Provisions", .american, "Portland", 2, .liked, "Charcuterie + frites.")

        // Okay
        add("Shake Shack", .burgers, "New York", 1, .okay, "Reliable, never thrilling.")
        add("Din Tai Fung", .chinese, "Seattle", 2, .okay, "Soup dumplings, big lines.")
        add("Sweetgreen", .cafe, "Boston", 2, .okay, "A salad is a salad.")
        add("Veggie Grill", .american, "Los Angeles", 2, .okay, "Fine when you need it.")
        add("Panera", .cafe, "Chicago", 1, .okay, "Bread bowl nostalgia.")
        add("Olive Garden", .italian, "Orlando", 2, .okay, "Breadsticks carry it.")
        add("Chipotle", .mexican, "Denver", 1, .okay, "Burrito math.")
        add("Pei Wei", .thai, "Dallas", 1, .okay, "Mall noodles.")
        add("California Pizza Kitchen", .pizza, "San Diego", 2, .okay, "BBQ chicken pizza.")
        add("Pret A Manger", .cafe, "Boston", 1, .okay, "Airport lunch energy.")
        add("Yard House", .american, "San Diego", 2, .okay, "Big menu, no soul.")
        add("Benihana", .japanese, "Miami", 3, .okay, "Onion volcano for the table.")
        add("Buca di Beppo", .italian, "Minneapolis", 2, .okay, "Family-style chaos.")
        add("Pho Hoa", .vietnamese, "San Jose", 1, .okay, "Solid bowl, no frills.")
        add("Noodles & Company", .thai, "Madison", 1, .okay, "Pad thai-ish.")

        // Extra liked/loved to push past 50 ranked
        add("State Bird Provisions", .american, "San Francisco", 3, .loved, "Dim-sum-style dishes.")
        add("Cane Rosso", .pizza, "Dallas", 2, .liked, "Neapolitan in Texas.")
        add("Han Dynasty", .chinese, "Philadelphia", 2, .liked, "Dan dan noodles.")
        add("Tatte", .bakery, "Boston", 2, .liked, "Shakshuka + pastries.")
        add("Cochon", .american, "New Orleans", 3, .liked, "Cajun done loud.")
        add("Jeju Noodle Bar", .korean, "New York", 3, .loved, "Michelin ramyun.")
        add("Birrieria Zaragoza", .mexican, "Chicago", 1, .loved, "Goat birria perfection.")
        add("Le Pigeon", .french, "Portland", 3, .liked, "Foie gras profiteroles.")
        add("Seafood City", .seafood, "Seattle", 2, .okay, "Solid fish counter.")

        // Wishlist (want to try)
        add("Atomix", .korean, "New York", 4, nil, "Tasting menu, hard res.")
        add("Single Thread", .american, "Healdsburg", 4, nil, "Farm + inn + 3 stars.")
        add("Kann", .vietnamese, "Portland", 3, nil, "Live-fire Haitian.")
        add("Lengua Madre", .mexican, "New Orleans", 3, nil, "Nuevo Mexican tasting.")
        add("Dhamaka", .indian, "New York", 3, nil, "Unapologetic Indian.")
        add("Sushi Sho", .japanese, "Honolulu", 4, nil, "Edomae omakase.")
        add("Camphor", .french, "Los Angeles", 3, nil, "French bistro buzz.")
        add("Anajak Thai", .thai, "Los Angeles", 2, nil, "Thai Taco Tuesday.")

        return e
    }
}

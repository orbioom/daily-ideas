import Foundation
import SwiftData

/// Seeds a realistic fragrance collection on first launch, behind the "didSeed" flag.
enum SeedData {

    private struct Entry {
        let name: String
        let house: String
        let conc: Concentration
        let status: BottleStatus
        let size: Double
        let price: Double
        let rating: Int
        let longevity: Int
        let sillage: Int
        let hue: Double
        let seasons: Set<Season>
        let occasions: Set<Occasion>
        let top: [String]
        let heart: [String]
        let base: [String]
        let note: String
    }

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        // Always make sure the note library exists, even if the user erased fragrances.
        let notes = NoteLibrary.ensureSeeded(context: context)
        guard !didSeed else { return }

        let baseDate = Date()
        let entries = catalog()

        for (i, e) in entries.enumerated() {
            let f = Fragrance(name: e.name,
                              house: e.house,
                              concentration: e.conc,
                              seasons: e.seasons,
                              occasions: e.occasions,
                              sizeML: e.size,
                              pricePaid: e.price,
                              bottlesOwned: e.status == .owned ? 1 : 0,
                              status: e.status,
                              rating: e.rating,
                              longevityRating: e.longevity,
                              sillageRating: e.sillage,
                              colorHue: e.hue,
                              notes: e.note,
                              addedAt: baseDate.addingTimeInterval(Double(-i) * 86_400 * 3))
            context.insert(f)
            attachNotes(to: f, slot: .top, names: e.top, notes: notes)
            attachNotes(to: f, slot: .heart, names: e.heart, notes: notes)
            attachNotes(to: f, slot: .base, names: e.base, notes: notes)
            attachWears(to: f, seedIndex: i, baseDate: baseDate)
        }

        try? context.save()
        didSeed = true
    }

    /// Wipe all fragrances (and cascaded wears/placements). Notes are kept as the library.
    static func clearFragrances(context: ModelContext) {
        let descriptor = FetchDescriptor<Fragrance>()
        if let all = try? context.fetch(descriptor) {
            for f in all { context.delete(f) }
            try? context.save()
        }
    }

    // MARK: Helpers

    private static func attachNotes(to f: Fragrance, slot: NoteSlot, names: [String], notes: [String: ScentNote]) {
        for (idx, name) in names.enumerated() {
            guard let note = notes[name] else { continue }
            let placement = NotePlacement(slot: slot, note: note, order: idx)
            placement.fragrance = f
            f.placements.append(placement)
        }
    }

    private static func attachWears(to f: Fragrance, seedIndex: Int, baseDate: Date) {
        // Only owned/decant bottles get wear logs; vary the count for a lively log.
        guard f.status.isInCollection else { return }
        let count = (seedIndex % 7)   // 0...6 wears
        let cal = Calendar.current
        let seasonPool: [Season?] = Array(f.seasons) + [nil]
        let occasionPool: [Occasion?] = Array(f.occasions) + [nil]
        for w in 0..<count {
            // Spread wears across the last ~150 days.
            let daysBack = (w * 17 + seedIndex * 3) % 150
            let date = cal.date(byAdding: .day, value: -daysBack, to: baseDate) ?? baseDate
            let season = seasonPool.isEmpty ? nil : seasonPool[(w + seedIndex) % seasonPool.count]
            let occasion = occasionPool.isEmpty ? nil : occasionPool[(w + seedIndex) % occasionPool.count]
            let log = WearLog(date: date, occasion: occasion, season: season ?? Season.current(for: date), note: "")
            log.fragrance = f
            f.wears.append(log)
        }
    }

    // MARK: Catalog (>=50 fragrances across houses, families, statuses)

    private static func catalog() -> [Entry] {
        var e: [Entry] = []
        func add(_ name: String, _ house: String, _ conc: Concentration, _ status: BottleStatus,
                 size: Double, price: Double, rating: Int, lon: Int, sil: Int, hue: Double,
                 seasons: Set<Season>, occasions: Set<Occasion>,
                 top: [String], heart: [String], base: [String], note: String = "") {
            e.append(Entry(name: name, house: house, conc: conc, status: status, size: size,
                           price: price, rating: rating, longevity: lon, sillage: sil, hue: hue,
                           seasons: seasons, occasions: occasions, top: top, heart: heart, base: base, note: note))
        }

        // Owned
        add("Aventus", "Creed", .edp, .owned, size: 100, price: 435, rating: 5, lon: 4, sil: 5, hue: 0.10,
            seasons: [.spring, .summer, .fall], occasions: [.office, .date, .evening, .leisure],
            top: ["Bergamot", "Grapefruit", "Pink Pepper"], heart: ["Patchouli", "Jasmine", "Rose"], base: ["Oakmoss", "Vanilla", "Ambroxan"],
            note: "The pineapple-smoke icon. My signature for big days.")
        add("Sauvage", "Dior", .edt, .owned, size: 100, price: 110, rating: 4, lon: 4, sil: 5, hue: 0.55,
            seasons: [.spring, .summer], occasions: [.daily, .office, .sport],
            top: ["Bergamot", "Pink Pepper"], heart: ["Lavender", "Pink Pepper"], base: ["Ambroxan", "Cedar"],
            note: "Ubiquitous for a reason — fresh, loud, easy.")
        add("Oud Wood", "Tom Ford", .edp, .owned, size: 50, price: 320, rating: 5, lon: 4, sil: 3, hue: 0.07,
            seasons: [.fall, .winter], occasions: [.evening, .formal, .date],
            top: ["Cardamom", "Black Pepper"], heart: ["Oud", "Sandalwood"], base: ["Vanilla", "Amber", "Tonka Bean"],
            note: "Smooth gateway oud. Cozy and refined.")
        add("Tobacco Vanille", "Tom Ford", .edp, .owned, size: 50, price: 295, rating: 5, lon: 5, sil: 5, hue: 0.06,
            seasons: [.fall, .winter], occasions: [.evening, .formal, .date],
            top: ["Black Pepper", "Saffron"], heart: ["Tonka Bean", "Cocoa"], base: ["Vanilla", "Tonka Bean", "Honey"],
            note: "Spiced rum and pipe tobacco. A winter hug.")
        add("Bleu de Chanel", "Chanel", .edp, .owned, size: 100, price: 135, rating: 4, lon: 4, sil: 4, hue: 0.5,
            seasons: [.spring, .fall], occasions: [.office, .formal, .date],
            top: ["Grapefruit", "Mint", "Pink Pepper"], heart: ["Cardamom", "Jasmine"], base: ["Sandalwood", "Cedar", "Amber"],
            note: "The dependable crowd-pleaser.")
        add("Santal 33", "Le Labo", .edp, .owned, size: 50, price: 220, rating: 4, lon: 4, sil: 3, hue: 0.12,
            seasons: [.fall, .winter, .spring], occasions: [.daily, .office, .leisure],
            top: ["Cardamom", "Violet"], heart: ["Iris", "Leather"], base: ["Sandalwood", "Cedar", "Amber"],
            note: "That coffee-shop sandalwood everyone wears.")
        add("Black Orchid", "Tom Ford", .edp, .owned, size: 50, price: 165, rating: 4, lon: 5, sil: 5, hue: 0.04,
            seasons: [.fall, .winter], occasions: [.evening, .date, .formal],
            top: ["Bergamot", "Black Pepper"], heart: ["Tuberose", "Orange Blossom", "Cocoa"], base: ["Patchouli", "Vanilla", "Vetiver"],
            note: "Dark, opulent, unmistakable.")
        add("Terre d'Hermès", "Hermès", .edp, .owned, size: 75, price: 130, rating: 5, lon: 4, sil: 4, hue: 0.45,
            seasons: [.spring, .fall], occasions: [.office, .daily, .leisure],
            top: ["Grapefruit", "Bitter Orange"], heart: ["Black Pepper", "Geranium"], base: ["Vetiver", "Cedar", "Benzoin"],
            note: "Mineral, peppery, timeless.")
        add("La Nuit de l'Homme", "YSL", .edt, .owned, size: 100, price: 95, rating: 5, lon: 3, sil: 4, hue: 0.08,
            seasons: [.fall, .winter, .spring], occasions: [.date, .evening],
            top: ["Cardamom", "Bergamot"], heart: ["Lavender", "Cedar"], base: ["Tonka Bean", "Vanilla"],
            note: "The date-night legend.")
        add("Layton", "Parfums de Marly", .edp, .owned, size: 125, price: 310, rating: 5, lon: 5, sil: 5, hue: 0.1,
            seasons: [.fall, .winter, .spring], occasions: [.office, .evening, .date, .formal],
            top: ["Bergamot", "Mandarin", "Lavender"], heart: ["Geranium", "Violet"], base: ["Vanilla", "Sandalwood", "Tonka Bean"],
            note: "Apple, lavender, and a vanilla cloud.")
        add("Reflection Man", "Amouage", .edp, .owned, size: 100, price: 340, rating: 5, lon: 4, sil: 4, hue: 0.16,
            seasons: [.spring, .summer], occasions: [.office, .formal, .leisure],
            top: ["Bergamot", "Petitgrain"], heart: ["Jasmine", "Ylang-Ylang", "Rose"], base: ["Sandalwood", "Cedar", "Vetiver"],
            note: "Elegant white-floral on wood.")
        add("Halloween", "Jesus del Pozo", .edt, .owned, size: 100, price: 45, rating: 3, lon: 3, sil: 3, hue: 0.7,
            seasons: [.spring], occasions: [.daily, .leisure],
            top: ["Bergamot", "Mandarin"], heart: ["Iris", "Violet"], base: ["White Musk", "Vanilla"],
            note: "A cheap powdery gem.")
        add("Acqua di Giò Profumo", "Armani", .edp, .owned, size: 75, price: 105, rating: 4, lon: 4, sil: 4, hue: 0.52,
            seasons: [.summer, .spring], occasions: [.office, .date, .leisure],
            top: ["Bergamot", "Sea Salt"], heart: ["Geranium", "Sea Salt"], base: ["Patchouli", "Frankincense"],
            note: "The smoky, grown-up aquatic.")
        add("Spicebomb Extreme", "Viktor & Rolf", .edp, .owned, size: 90, price: 115, rating: 4, lon: 5, sil: 5, hue: 0.09,
            seasons: [.fall, .winter], occasions: [.evening, .date],
            top: ["Black Pepper", "Cinnamon"], heart: ["Cardamom", "Lavender"], base: ["Vanilla", "Tonka Bean"],
            note: "Spiced vanilla tobacco bomb.")
        add("Mojave Ghost", "Byredo", .edp, .owned, size: 50, price: 196, rating: 4, lon: 3, sil: 2, hue: 0.18,
            seasons: [.spring, .summer], occasions: [.daily, .office, .leisure],
            top: ["Ambrette", "Bergamot"], heart: ["Violet", "Jasmine"], base: ["Sandalwood", "Cedar", "Ambrette"],
            note: "Soft, skin-like, inoffensive.")
        add("Y EDP", "YSL", .edp, .owned, size: 100, price: 100, rating: 4, lon: 4, sil: 4, hue: 0.5,
            seasons: [.spring, .fall], occasions: [.office, .daily, .date],
            top: ["Bergamot", "Mint"], heart: ["Geranium", "Basil"], base: ["Amber", "Cedar", "Vetiver"],
            note: "Crisp fresh-fougère for the office.")
        add("Ombré Leather", "Tom Ford", .edp, .owned, size: 100, price: 195, rating: 4, lon: 4, sil: 4, hue: 0.08,
            seasons: [.fall, .winter, .spring], occasions: [.evening, .daily, .date],
            top: ["Cardamom"], heart: ["Leather", "Jasmine"], base: ["Patchouli", "Amber", "Suede"],
            note: "Suede and bloom — easy leather.")
        add("Erba Pura", "Xerjoff", .edp, .owned, size: 100, price: 245, rating: 5, lon: 5, sil: 5, hue: 0.6,
            seasons: [.summer, .spring], occasions: [.leisure, .date, .daily],
            top: ["Mandarin", "Lemon"], heart: ["Orange Blossom"], base: ["White Musk", "Amber", "Vanilla"],
            note: "Fizzy fruit candy that lasts forever.")

        // Decants
        add("Baccarat Rouge 540", "MFK", .extrait, .decant, size: 5, price: 60, rating: 5, lon: 5, sil: 5, hue: 0.05,
            seasons: [.fall, .winter], occasions: [.evening, .date, .formal],
            top: ["Saffron"], heart: ["Jasmine"], base: ["Amber", "Cedar", "Ambroxan"],
            note: "The viral burnt-sugar amber. A small decant goes far.")
        add("Pegasus", "Parfums de Marly", .edp, .decant, size: 10, price: 30, rating: 4, lon: 4, sil: 4, hue: 0.1,
            seasons: [.fall, .winter, .spring], occasions: [.office, .date, .daily],
            top: ["Bergamot", "Bitter Orange"], heart: ["Tonka Bean", "Vanilla"], base: ["Vanilla", "Sandalwood"],
            note: "Creamy almond-vanilla. Decant before I commit.")
        add("Grand Soir", "MFK", .edp, .decant, size: 8, price: 40, rating: 5, lon: 5, sil: 4, hue: 0.07,
            seasons: [.fall, .winter], occasions: [.evening, .formal, .date],
            top: ["Labdanum"], heart: ["Benzoin", "Amber"], base: ["Vanilla", "Tonka Bean", "Labdanum"],
            note: "Amber-vanilla in a tuxedo.")
        add("Side Effect", "Initio", .edp, .decant, size: 8, price: 38, rating: 4, lon: 5, sil: 5, hue: 0.06,
            seasons: [.fall, .winter], occasions: [.evening, .date],
            top: ["Cinnamon", "Saffron"], heart: ["Tonka Bean"], base: ["Vanilla", "Honey", "Tonka Bean"],
            note: "Boozy vanilla tobacco. Testing the hype.")

        // Wishlist
        add("Encre Noire", "Lalique", .edt, .wishlist, size: 100, price: 60, rating: 0, lon: 4, sil: 3, hue: 0.2,
            seasons: [.fall, .winter], occasions: [.evening, .daily],
            top: ["Cedar"], heart: ["Vetiver"], base: ["Vetiver", "White Musk", "Cedar"],
            note: "Dark vetiver, legendary value.")
        add("Interlude Man", "Amouage", .edp, .wishlist, size: 100, price: 330, rating: 0, lon: 5, sil: 5, hue: 0.09,
            seasons: [.fall, .winter], occasions: [.evening, .formal],
            top: ["Bergamot", "Black Pepper"], heart: ["Frankincense", "Oud"], base: ["Leather", "Labdanum", "Patchouli"],
            note: "The smoky beast I keep eyeing.")
        add("PHANTOM", "Paco Rabanne", .edt, .wishlist, size: 100, price: 90, rating: 0, lon: 3, sil: 3, hue: 0.55,
            seasons: [.summer, .spring], occasions: [.daily, .leisure, .sport],
            top: ["Lemon", "Lavender"], heart: ["Lavender"], base: ["Vanilla", "Patchouli"],
            note: "Fun lavender-vanilla clubber.")
        add("Vetiver", "Guerlain", .edt, .wishlist, size: 100, price: 95, rating: 0, lon: 3, sil: 3, hue: 0.22,
            seasons: [.spring, .summer], occasions: [.office, .daily],
            top: ["Lemon", "Bergamot"], heart: ["Vetiver", "Black Pepper"], base: ["Vetiver", "Cedar"],
            note: "The classic green vetiver benchmark.")
        add("L'Homme Idéal", "Guerlain", .edp, .wishlist, size: 100, price: 105, rating: 0, lon: 4, sil: 3, hue: 0.13,
            seasons: [.fall, .winter], occasions: [.date, .office],
            top: ["Bergamot", "Lemon"], heart: ["Cinnamon", "Praline"], base: ["Tonka Bean", "Vanilla", "Leather"],
            note: "Cherry-almond gourmand.")
        add("Mandarino di Amalfi", "Tom Ford", .edt, .wishlist, size: 50, price: 230, rating: 0, lon: 3, sil: 3, hue: 0.62,
            seasons: [.summer], occasions: [.leisure, .daily],
            top: ["Mandarin", "Lemon", "Bergamot"], heart: ["Orange Blossom", "Jasmine"], base: ["Amber", "White Musk"],
            note: "Sunny citrus escapism.")
        add("Halston Z-14", "Halston", .edp, .wishlist, size: 75, price: 35, rating: 0, lon: 4, sil: 4, hue: 0.3,
            seasons: [.fall, .winter], occasions: [.evening, .formal],
            top: ["Lemon", "Bergamot"], heart: ["Cinnamon", "Geranium"], base: ["Oakmoss", "Leather", "Amber"],
            note: "A vintage chypre powerhouse.")

        // Sold
        add("Stronger With You", "Armani", .edt, .sold, size: 100, price: 70, rating: 3, lon: 3, sil: 3, hue: 0.12,
            seasons: [.fall, .winter], occasions: [.date, .daily],
            top: ["Cardamom", "Pink Pepper"], heart: ["Lavender", "Geranium"], base: ["Vanilla", "Cocoa", "Tonka Bean"],
            note: "Nice but too common for me — moved it on.")
        add("Eros", "Versace", .edt, .sold, size: 100, price: 65, rating: 2, lon: 4, sil: 5, hue: 0.5,
            seasons: [.fall, .winter], occasions: [.evening, .daily],
            top: ["Mint", "Lemon"], heart: ["Tonka Bean", "Geranium"], base: ["Vanilla", "Vetiver", "Cedar"],
            note: "Too sharp-sweet for my taste.")

        // Extra owned to comfortably clear 50 total
        add("Dior Homme Intense", "Dior", .edp, .owned, size: 100, price: 130, rating: 5, lon: 5, sil: 4, hue: 0.14,
            seasons: [.fall, .winter, .spring], occasions: [.formal, .date, .evening],
            top: ["Lavender"], heart: ["Iris", "Ambrette"], base: ["Vetiver", "Cedar", "Vanilla"],
            note: "The makeup-bag iris masterpiece.")
        add("Fahrenheit", "Dior", .edt, .owned, size: 100, price: 100, rating: 4, lon: 4, sil: 4, hue: 0.4,
            seasons: [.fall, .spring], occasions: [.daily, .leisure],
            top: ["Mandarin", "Bergamot"], heart: ["Violet", "Nutmeg"], base: ["Leather", "Vetiver", "Patchouli"],
            note: "Petrol-violet weirdness I love.")
        add("Green Irish Tweed", "Creed", .edp, .owned, size: 75, price: 350, rating: 4, lon: 3, sil: 3, hue: 0.25,
            seasons: [.spring, .summer], occasions: [.office, .formal],
            top: ["Lemon", "Petitgrain"], heart: ["Violet", "Geranium"], base: ["Sandalwood", "Ambrette"],
            note: "The elegant green benchmark.")
        add("L'Eau d'Issey", "Issey Miyake", .edt, .owned, size: 75, price: 70, rating: 4, lon: 3, sil: 3, hue: 0.55,
            seasons: [.summer, .spring], occasions: [.office, .daily, .sport],
            top: ["Yuzu", "Bergamot"], heart: ["Geranium", "Nutmeg"], base: ["Cedar", "Vetiver", "Amber"],
            note: "The blueprint aquatic.")
        add("Wood Sage & Sea Salt", "Jo Malone", .edc, .owned, size: 100, price: 80, rating: 4, lon: 2, sil: 2, hue: 0.35,
            seasons: [.summer, .spring], occasions: [.daily, .leisure, .sport],
            top: ["Bergamot", "Sea Salt"], heart: ["Sea Salt"], base: ["Sandalwood", "Ambrette"],
            note: "A breezy beach in a bottle.")
        add("English Pear & Freesia", "Jo Malone", .edc, .owned, size: 100, price: 80, rating: 3, lon: 2, sil: 2, hue: 0.45,
            seasons: [.spring, .fall], occasions: [.daily, .office],
            top: ["Bitter Orange"], heart: ["Orange Blossom", "Rose"], base: ["Patchouli", "Amber"],
            note: "Crisp autumn pear.")
        add("Tam Dao", "Diptyque", .edp, .owned, size: 75, price: 165, rating: 5, lon: 4, sil: 3, hue: 0.16,
            seasons: [.fall, .winter, .spring], occasions: [.office, .daily, .leisure],
            top: ["Cedar"], heart: ["Sandalwood", "Rose"], base: ["Sandalwood", "Cedar", "Amber"],
            note: "Creamy meditative sandalwood.")
        add("Philosykos", "Diptyque", .edt, .owned, size: 75, price: 140, rating: 4, lon: 3, sil: 3, hue: 0.3,
            seasons: [.summer, .spring], occasions: [.daily, .leisure],
            top: ["Fig Leaf"], heart: ["Fig Leaf", "Green Tea"], base: ["Cedar", "White Musk"],
            note: "The whole fig tree — leaf, fruit, wood.")
        add("Aqua Universalis", "MFK", .edp, .owned, size: 70, price: 195, rating: 4, lon: 3, sil: 3, hue: 0.5,
            seasons: [.spring, .summer], occasions: [.office, .formal, .date],
            top: ["Bergamot", "Lemon"], heart: ["Jasmine", "Orange Blossom"], base: ["White Musk", "Sandalwood"],
            note: "Clean-laundry elegance.")
        add("Oud Satin Mood", "MFK", .edp, .owned, size: 70, price: 290, rating: 5, lon: 5, sil: 4, hue: 0.05,
            seasons: [.fall, .winter], occasions: [.evening, .formal, .date],
            top: ["Violet"], heart: ["Rose", "Oud"], base: ["Vanilla", "Benzoin", "Amber"],
            note: "Velvety rose-oud-vanilla.")
        add("1 Million", "Paco Rabanne", .edt, .owned, size: 100, price: 75, rating: 3, lon: 4, sil: 4, hue: 0.6,
            seasons: [.fall, .winter], occasions: [.evening, .leisure],
            top: ["Grapefruit", "Mint", "Bitter Orange"], heart: ["Cinnamon", "Rose"], base: ["Leather", "Amber", "Patchouli"],
            note: "The blingy crowd-pleaser.")
        add("Invictus", "Paco Rabanne", .edt, .owned, size: 100, price: 75, rating: 3, lon: 3, sil: 4, hue: 0.55,
            seasons: [.summer, .spring], occasions: [.sport, .leisure, .daily],
            top: ["Grapefruit", "Sea Salt"], heart: ["Jasmine", "Basil"], base: ["Amber", "Patchouli", "White Musk"],
            note: "Gym-bag fresh.")
        add("Nautica Voyage", "Nautica", .edt, .owned, size: 100, price: 25, rating: 4, lon: 3, sil: 3, hue: 0.55,
            seasons: [.summer, .spring], occasions: [.daily, .sport, .leisure],
            top: ["Bergamot"], heart: ["Jasmine", "Sea Salt"], base: ["Cedar", "White Musk", "Amber"],
            note: "Unbeatable cheap aquatic.")
        add("Club de Nuit Intense", "Armaf", .edt, .owned, size: 105, price: 35, rating: 4, lon: 5, sil: 5, hue: 0.1,
            seasons: [.spring, .summer, .fall], occasions: [.office, .evening, .leisure],
            top: ["Lemon", "Bergamot", "Pink Pepper"], heart: ["Jasmine", "Rose"], base: ["Vanilla", "Oakmoss", "Ambroxan"],
            note: "The famous Aventus-adjacent value king.")
        add("Tobacco Oud", "Tom Ford", .edp, .owned, size: 50, price: 280, rating: 4, lon: 5, sil: 5, hue: 0.05,
            seasons: [.winter], occasions: [.evening, .formal],
            top: ["Cinnamon", "Black Pepper"], heart: ["Oud", "Cocoa"], base: ["Tonka Bean", "Sandalwood", "Amber"],
            note: "Smoky spiced wood for deep winter.")
        add("Bois d'Argent", "Dior", .edp, .owned, size: 125, price: 290, rating: 5, lon: 4, sil: 3, hue: 0.18,
            seasons: [.fall, .winter], occasions: [.formal, .office],
            top: ["Iris", "Lavender"], heart: ["Iris", "Honey"], base: ["Myrrh", "Sandalwood", "Amber"],
            note: "Honeyed iris and incense.")
        add("Vetiver", "Tom Ford", .edp, .owned, size: 50, price: 175, rating: 4, lon: 3, sil: 3, hue: 0.2,
            seasons: [.spring, .summer], occasions: [.office, .daily],
            top: ["Grapefruit", "Bergamot"], heart: ["Vetiver", "Pink Pepper"], base: ["Vetiver", "Amber", "Leather"],
            note: "Bright grapefruit vetiver.")
        add("Rose 31", "Le Labo", .edp, .owned, size: 50, price: 220, rating: 4, lon: 4, sil: 3, hue: 0.4,
            seasons: [.fall, .spring], occasions: [.office, .date, .evening],
            top: ["Black Pepper", "Cardamom"], heart: ["Rose", "Cardamom"], base: ["Cedar", "Vetiver", "Oud"],
            note: "A rose for everyone — spicy, woody.")
        add("Bergamote 22", "Le Labo", .edp, .owned, size: 50, price: 220, rating: 4, lon: 3, sil: 3, hue: 0.5,
            seasons: [.summer, .spring], occasions: [.daily, .office, .leisure],
            top: ["Bergamot", "Grapefruit", "Petitgrain"], heart: ["Orange Blossom"], base: ["White Musk", "Amber", "Vetiver"],
            note: "Sparkling citrus musk.")
        add("Eau Sauvage", "Dior", .edt, .owned, size: 100, price: 95, rating: 5, lon: 3, sil: 3, hue: 0.5,
            seasons: [.spring, .summer], occasions: [.office, .formal, .daily],
            top: ["Lemon", "Bergamot", "Basil"], heart: ["Jasmine", "Geranium"], base: ["Oakmoss", "Vetiver", "Amber"],
            note: "The 1966 chypre that still sings.")
        add("Habit Rouge", "Guerlain", .edt, .owned, size: 100, price: 90, rating: 4, lon: 4, sil: 3, hue: 0.35,
            seasons: [.fall, .winter], occasions: [.formal, .evening],
            top: ["Bergamot", "Lemon", "Bitter Orange"], heart: ["Cinnamon", "Rose"], base: ["Vanilla", "Leather", "Benzoin"],
            note: "Powdery vanilla-leather elegance.")
        add("CK One", "Calvin Klein", .edt, .owned, size: 100, price: 30, rating: 3, lon: 2, sil: 2, hue: 0.45,
            seasons: [.summer, .spring], occasions: [.daily, .leisure, .sport],
            top: ["Bergamot", "Mandarin", "Green Tea"], heart: ["Jasmine", "Violet", "Nutmeg"], base: ["White Musk", "Amber", "Oakmoss"],
            note: "90s nostalgia, still fresh.")
        add("Allure Homme Sport", "Chanel", .edt, .owned, size: 100, price: 105, rating: 4, lon: 3, sil: 3, hue: 0.5,
            seasons: [.summer, .spring], occasions: [.sport, .daily, .office],
            top: ["Bitter Orange", "Sea Salt"], heart: ["Pink Pepper", "Cedar"], base: ["White Musk", "Amber", "Vetiver"],
            note: "Effortless clean citrus.")
        add("Aqua Allegoria Mandarine Basilic", "Guerlain", .edt, .owned, size: 75, price: 85, rating: 4, lon: 2, sil: 2, hue: 0.62,
            seasons: [.summer], occasions: [.daily, .leisure],
            top: ["Mandarin", "Lemon", "Basil"], heart: ["Basil", "Green Tea"], base: ["White Musk", "Amber"],
            note: "Bright kitchen-garden citrus.")
        add("Replica Jazz Club", "Maison Margiela", .edt, .owned, size: 100, price: 135, rating: 4, lon: 4, sil: 3, hue: 0.12,
            seasons: [.fall, .winter], occasions: [.evening, .date],
            top: ["Pink Pepper", "Lemon"], heart: ["Tonka Bean", "Honey"], base: ["Vanilla", "Tonka Bean", "Benzoin"],
            note: "Boozy tobacco lounge.")
        add("Replica By the Fireplace", "Maison Margiela", .edt, .owned, size: 100, price: 135, rating: 5, lon: 4, sil: 4, hue: 0.1,
            seasons: [.winter, .fall], occasions: [.evening, .leisure, .daily],
            top: ["Pink Pepper", "Cinnamon"], heart: ["Cocoa", "Guaiac Wood"], base: ["Vanilla", "Cedar", "Birch Tar"],
            note: "Roasted chestnuts and woodsmoke.")

        return e
    }
}

import Foundation
import SwiftData

/// Seeds realistic first-run demo content: a rich set of loyalty cards across every
/// category plus several gift cards with logged spend history, so the Wallet, Gift
/// Cards, and Insights screens feel alive immediately. Gated behind a `didSeed` flag.
enum SeedData {

    /// A small deterministic generator so sample data is stable across runs.
    private struct RNG {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
        mutating func int(_ upperExclusive: Int) -> Int {
            guard upperExclusive > 0 else { return 0 }
            return Int(next() % UInt64(upperExclusive))
        }
    }

    /// Generate a valid 13-digit EAN-13 from a 12-digit base seed.
    private static func ean13(seed: Int) -> String {
        var base = String(format: "%012d", abs(seed) % 1_000_000_000_000)
        if base.count > 12 { base = String(base.suffix(12)) }
        let digits = base.compactMap { $0.wholeNumberValue }
        let check = EAN13Encoder.checkDigit(forFirst12: digits) ?? 0
        return base + String(check)
    }

    /// A numeric code of `length` digits for Code128 membership numbers.
    private static func numericCode(_ length: Int, rng: inout RNG) -> String {
        var s = ""
        for _ in 0..<length { s.append(String(rng.int(10))) }
        return s
    }

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertSampleLoyaltyCards(context: context)
        insertSampleGiftCards(context: context)
        didSeed = true
    }

    /// Insert 50+ loyalty cards spanning categories, formats, favorites, and usage.
    static func insertSampleLoyaltyCards(context: ModelContext) {
        var rng = RNG(seed: 0x57A54_1234_ABCD)
        let cal = Calendar.current
        let now = Date()

        // Pull names from the catalog, then top up with extra named entries so we
        // comfortably clear 50 realistic cards.
        var stores: [(name: String, store: String, category: CardCategory, color: String, format: BarcodeFormat)] = []

        for entry in StoreCatalog.all {
            stores.append((entry.name, entry.name, entry.category, entry.colorHex, entry.suggestedFormat))
        }

        let extras: [(String, CardCategory, String, BarcodeFormat)] = [
            ("Corner Pantry", .grocery, "#3B7A2E", .ean13),
            ("FreshLine Co-op", .grocery, "#1E7D5A", .ean13),
            ("ValuMart", .grocery, "#C0561E", .code128),
            ("CareFirst Rx", .pharmacy, "#2D6CDF", .code128),
            ("HealthHub", .pharmacy, "#0E7C86", .code128),
            ("Bean Theory", .coffee, "#6F4E37", .qr),
            ("Cafe Aurora", .coffee, "#7B3F00", .qr),
            ("UrbanThreads", .retail, "#34495E", .code128),
            ("TechBay", .retail, "#1F3A93", .code128),
            ("PageTurner Books", .retail, "#7D3C98", .ean13),
            ("PetParade", .retail, "#C0392B", .qr),
            ("StyleHaus", .retail, "#B0306E", .code128),
            ("AeroOne", .airline, "#1A5276", .pdf417),
            ("CloudFly", .airline, "#117864", .aztec),
            ("FuelMax", .fuel, "#D68910", .code128),
            ("PetroPlus", .fuel, "#B7950B", .code128),
            ("Noodle House", .dining, "#922B21", .qr),
            ("GrillWorks", .dining, "#A04000", .code128),
            ("CoreStrength", .fitness, "#16A085", .qr),
            ("Velocity Cycle", .fitness, "#117A65", .qr),
            ("StarPlex Cinema", .entertainment, "#6C3483", .qr),
            ("Funland", .entertainment, "#283593", .qr),
            ("Trailhead Outdoors", .retail, "#4C8C2B", .ean13),
            ("Bloom & Petal", .retail, "#AD1457", .qr),
            ("QuickClean Laundry", .other, "#455A64", .code128),
            ("CityTransit", .other, "#0B5394", .aztec),
            ("Harbor Hardware", .retail, "#5D4037", .code128),
            ("SunCitrus Juice", .dining, "#D4AC0D", .qr)
        ]
        for e in extras {
            stores.append((e.0, e.0, e.1, e.2, e.3))
        }

        for (index, s) in stores.enumerated() {
            let code: String
            switch s.format {
            case .ean13:
                code = ean13(seed: 100000000000 + index * 778361)
            case .upca:
                code = numericCode(12, rng: &rng)
            case .code128:
                code = numericCode(10 + rng.int(4), rng: &rng)
            case .qr:
                code = "STASH-\(s.name.replacingOccurrences(of: " ", with: "").uppercased())-\(numericCode(6, rng: &rng))"
            case .aztec:
                code = "AZ\(numericCode(9, rng: &rng))"
            case .pdf417:
                code = "PASS\(numericCode(8, rng: &rng))"
            }

            let isFav = index % 7 == 0
            let usedDaysAgo = rng.int(40)
            let lastUsed: Date? = (index % 3 == 0)
                ? cal.date(byAdding: .day, value: -usedDaysAgo, to: now)
                : nil
            let createdDaysAgo = 60 + rng.int(300)
            let created = cal.date(byAdding: .day, value: -createdDaysAgo, to: now) ?? now

            let card = LoyaltyCard(
                name: s.name,
                storeName: s.store,
                codeValue: code,
                format: s.format,
                category: s.category,
                colorHex: s.color,
                notes: "",
                isFavorite: isFav,
                createdAt: created,
                lastUsedAt: lastUsed
            )
            context.insert(card)
        }
        try? context.save()
    }

    /// Insert several gift cards with logged spend transactions and varied states.
    static func insertSampleGiftCards(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        struct GiftSeed {
            let store: String
            let color: String
            let format: BarcodeFormat
            let initial: Decimal
            let spends: [(Decimal, String, Int)]   // amount, note, daysAgo
            let expiryDays: Int?
        }

        let seeds: [GiftSeed] = [
            GiftSeed(store: "Roastery Coffee", color: "#5B3A29", format: .qr,
                     initial: 50,
                     spends: [(4.75, "Latte", 18), (6.20, "Cold brew + pastry", 9), (4.75, "Latte", 2)],
                     expiryDays: 210),
            GiftSeed(store: "Metro Outfitters", color: "#34495E", format: .code128,
                     initial: 100,
                     spends: [(38.40, "Jacket", 45), (12.00, "Socks", 20)],
                     expiryDays: nil),
            GiftSeed(store: "GadgetWorks", color: "#2C3E91", format: .code128,
                     initial: 75,
                     spends: [(75.00, "Headphones", 60)],
                     expiryDays: nil),
            GiftSeed(store: "Trattoria Uno", color: "#922B21", format: .qr,
                     initial: 40,
                     spends: [(22.50, "Dinner for two", 12)],
                     expiryDays: 25),
            GiftSeed(store: "HomeNest", color: "#C0561E", format: .ean13,
                     initial: 60,
                     spends: [],
                     expiryDays: 400),
            GiftSeed(store: "Cinematic", color: "#6C3483", format: .qr,
                     initial: 30,
                     spends: [(13.50, "Two tickets", 30), (8.00, "Popcorn", 30)],
                     expiryDays: 90),
            GiftSeed(store: "Bloom Boutique", color: "#B0306E", format: .qr,
                     initial: 45,
                     spends: [(45.00, "Bouquet", 5)],
                     expiryDays: -10)   // already expired & depleted
        ]

        for seed in seeds {
            let expiry: Date? = seed.expiryDays.flatMap {
                cal.date(byAdding: .day, value: $0, to: now)
            }
            let code: String
            switch seed.format {
            case .ean13: code = ean13(seed: 200000000000)
            case .qr:    code = "GIFT-\(seed.store.replacingOccurrences(of: " ", with: "").uppercased())"
            default:     code = "GC\(Int(NSDecimalNumber(decimal: seed.initial).doubleValue))\(seed.store.count)847261"
            }

            let card = GiftCard(
                storeName: seed.store,
                code: code,
                format: seed.format,
                initialBalance: seed.initial,
                currencyCode: "USD",
                expiryDate: expiry,
                colorHex: seed.color,
                notes: "",
                createdAt: cal.date(byAdding: .day, value: -120, to: now) ?? now
            )
            context.insert(card)

            for spend in seed.spends {
                let date = cal.date(byAdding: .day, value: -spend.2, to: now) ?? now
                let tx = BalanceTransaction(amount: spend.0, note: spend.1, date: date, giftCard: card)
                context.insert(tx)
                card.transactions.append(tx)
            }
        }
        try? context.save()
    }

    /// Delete all user data (both card types and their transactions).
    static func clearAll(context: ModelContext) {
        if let cards = try? context.fetch(FetchDescriptor<LoyaltyCard>()) {
            for c in cards { context.delete(c) }
        }
        if let gifts = try? context.fetch(FetchDescriptor<GiftCard>()) {
            for g in gifts { context.delete(g) }
        }
        try? context.save()
    }
}

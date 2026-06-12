import Foundation
import SwiftData

/// Seeds a small starter shelf with brews so the log, the bean detail and the
/// stats charts are alive on first launch.
enum SeedData {
    @MainActor
    static func installIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Bean>())) ?? 0
        guard count == 0 else { return }
        let cal = Calendar.current

        // Bean 1 — a fresh single origin, dialled across a few shots.
        let b1 = Bean(name: "Kayon Mountain", roaster: "Onyx", origin: "Ethiopia, Guji",
                      roastLevel: .light, process: .washed,
                      roastDate: cal.date(byAdding: .day, value: -9, to: Date()),
                      pricePaid: 22, bagSizeGrams: 250,
                      notes: "Floral, peach, bergamot. Espresso target ~1:2.2.")
        context.insert(b1)
        let shots: [(Int, Double, Double, Double, String, Int, Taste)] = [
            (7, 18, 30, 22, "5.2", 5, .sour),
            (5, 18, 38, 33, "4.6", 7, .bitter),
            (3, 18, 40, 29, "4.9", 9, .balanced),
            (1, 18, 41, 30, "4.9", 9, .balanced),
        ]
        for s in shots {
            let brew = Brew(method: .espresso,
                            date: cal.date(byAdding: .day, value: -s.0, to: Date()) ?? Date(),
                            doseGrams: s.1, outputGrams: s.2, timeSeconds: s.3,
                            grindSetting: s.4, waterTempC: 93, ratingHalf: s.5, taste: s.6,
                            notes: s.6 == .balanced ? "Dialed in!" : "")
            brew.bean = b1; b1.brews.append(brew); b1.gramsUsed += s.1
            context.insert(brew)
        }

        // Bean 2 — a comfort medium roast for filter.
        let b2 = Bean(name: "Hair Bender", roaster: "Stumptown", origin: "Blend",
                      roastLevel: .mediumDark, process: .washed,
                      roastDate: cal.date(byAdding: .day, value: -18, to: Date()),
                      pricePaid: 17, bagSizeGrams: 340,
                      notes: "Classic, chocolatey, forgiving.")
        context.insert(b2)
        let pours: [(Int, Double, Double, Double, Int, Taste)] = [
            (6, 22, 352, 180, 8, .balanced),
            (2, 20, 320, 175, 7, .balanced),
        ]
        for p in pours {
            let brew = Brew(method: .pourover,
                            date: cal.date(byAdding: .day, value: -p.0, to: Date()) ?? Date(),
                            doseGrams: p.1, outputGrams: p.2, timeSeconds: p.3,
                            grindSetting: "18", waterTempC: 94, ratingHalf: p.4, taste: p.5)
            brew.bean = b2; b2.brews.append(brew); b2.gramsUsed += p.1
            context.insert(brew)
        }

        try? context.save()
    }
}

import Foundation
import SwiftData

enum SeedData {
    static func seed(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        func opened(_ daysAgo: Int) -> Date { cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now }

        let cleanser = Product(name: "Gentle Gel Cleanser", brand: "Lumi", category: .cleanser,
                               openedDate: opened(40), paoMonths: 12, price: 14)
        let vitC = Product(name: "Vitamin C 10%", brand: "Glow Lab", category: .serum,
                           openedDate: opened(150), paoMonths: 6, price: 32)
        let moist = Product(name: "Barrier Repair Cream", brand: "Lumi", category: .moisturizer,
                            openedDate: opened(20), paoMonths: 12, price: 22)
        let spf = Product(name: "Daily SPF 50", brand: "Solé", category: .sunscreen,
                          openedDate: opened(70), paoMonths: 12, price: 18)
        let retinol = Product(name: "Retinol 0.3%", brand: "Night Shift", category: .treatment,
                              openedDate: opened(165), paoMonths: 6, price: 28)
        let toner = Product(name: "Hydrating Toner", brand: "Aqua", category: .toner,
                            openedDate: opened(10), paoMonths: 12, price: 16)
        let exfo = Product(name: "BHA Exfoliant", brand: "Clear", category: .exfoliant,
                           openedDate: nil, paoMonths: 6, price: 24)
        [cleanser, vitC, moist, spf, retinol, toner, exfo].forEach { context.insert($0) }

        // AM routine
        let am: [(Product?, String)] = [(cleanser, ""), (toner, ""), (vitC, ""), (moist, ""), (spf, "")]
        for (i, (p, _)) in am.enumerated() {
            let s = RoutineStep(routine: .am, order: i, product: p)
            context.insert(s)
        }
        // PM routine
        let pm: [Product?] = [cleanser, toner, retinol, moist]
        for (i, p) in pm.enumerated() {
            context.insert(RoutineStep(routine: .pm, order: i, product: p))
        }
        // Weekly
        context.insert(RoutineStep(routine: .weekly, order: 0, product: exfo,
                                   instruction: "Once or twice a week, PM only"))

        try? context.save()

        // Routine logs for the last ~10 days (mostly complete) to seed a streak.
        let amSteps = SkincareEngine.steps(fetchSteps(context), for: .am)
        let pmSteps = SkincareEngine.steps(fetchSteps(context), for: .pm)
        for offset in 1...10 {
            let day = cal.date(byAdding: .day, value: -offset, to: now) ?? now
            if offset != 4 { // a small gap for realism
                let amLog = RoutineLog(date: day, routine: .am, doneStepUUIDs: amSteps.map { $0.uuid })
                context.insert(amLog)
            }
            if offset % 2 == 1 {
                let pmLog = RoutineLog(date: day, routine: .pm, doneStepUUIDs: pmSteps.map { $0.uuid })
                context.insert(pmLog)
            }
        }

        // Skin logs
        let ratings = [3, 3, 4, 4, 3, 4, 5, 4]
        for (i, r) in ratings.enumerated() {
            let day = cal.date(byAdding: .day, value: -(i * 3 + 1), to: now) ?? now
            let concerns: [SkinConcern] = r >= 4 ? [.calm] : [.dryness, .dullness]
            context.insert(SkinLog(date: day, rating: r, concerns: concerns))
        }

        try? context.save()
    }

    private static func fetchSteps(_ context: ModelContext) -> [RoutineStep] {
        (try? context.fetch(FetchDescriptor<RoutineStep>())) ?? []
    }
}

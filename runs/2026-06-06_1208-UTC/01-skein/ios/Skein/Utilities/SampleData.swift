import Foundation
import SwiftData

/// Seeds a realistic starter set so the app feels alive on first run.
/// Reachable again from Settings; empty states return once data is deleted.
enum SampleData {
    static func seed(into context: ModelContext) {
        let raglan = Project(name: "Weekend Raglan", craft: .knit,
                             yarn: "Cascade 220", tool: "US 7 / 4.5 mm")
        raglan.gaugeStitches = 18; raglan.gaugeRows = 24
        raglan.notes = "Top-down, contiguous sleeves. Body in the round."
        let rows = Counter(name: "Body rows", value: 64, step: 1, sortIndex: 0)
        let lace = Counter(name: "Lace chart", value: 13, step: 1, repeatLength: 8, sortIndex: 1)
        raglan.counters = [rows, lace]

        let socks = Project(name: "Vanilla Socks", craft: .knit,
                            yarn: "Regia 4-ply", tool: "US 1 / 2.25 mm")
        socks.gaugeStitches = 32; socks.gaugeRows = 44
        socks.status = .hibernating
        socks.counters = [Counter(name: "Cuff rounds", value: 12, step: 1, repeatLength: 2, sortIndex: 0)]

        let blanket = Project(name: "Granny Blanket", craft: .crochet,
                              yarn: "Stylecraft Special DK", tool: "4.0 mm")
        blanket.gaugeStitches = 20; blanket.gaugeRows = 11
        blanket.counters = [Counter(name: "Rounds", value: 28, step: 1, sortIndex: 0)]

        let shawl = Project(name: "Garter Shawl", craft: .knit, yarn: "Malabrigo Sock", tool: "US 5 / 3.75 mm")
        shawl.gaugeStitches = 22; shawl.gaugeRows = 40
        shawl.status = .finished
        shawl.counters = [Counter(name: "Rows", value: 312, step: 2, sortIndex: 0)]

        for p in [raglan, socks, blanket, shawl] { context.insert(p) }

        let yarns: [StashYarn] = [
            { let y = StashYarn(name: "Cascade 220", brand: "Cascade", weight: .medium, skeins: 6, yardsPerSkein: 220)
              y.fiber = "Wool"; y.colorName = "Heather Grey"; y.gramsPerSkein = 100; return y }(),
            { let y = StashYarn(name: "Regia 4-ply", brand: "Schachenmayr", weight: .superFine, skeins: 2, yardsPerSkein: 459)
              y.fiber = "Wool/Nylon"; y.colorName = "Denim"; y.gramsPerSkein = 100; return y }(),
            { let y = StashYarn(name: "Special DK", brand: "Stylecraft", weight: .light, skeins: 10, yardsPerSkein: 322)
              y.fiber = "Acrylic"; y.colorName = "Sage"; y.gramsPerSkein = 100; return y }(),
            { let y = StashYarn(name: "Sock", brand: "Malabrigo", weight: .superFine, skeins: 3, yardsPerSkein: 440)
              y.fiber = "Merino"; y.colorName = "Arco Iris"; y.gramsPerSkein = 100; return y }(),
            { let y = StashYarn(name: "Brava Worsted", brand: "Knit Picks", weight: .medium, skeins: 5, yardsPerSkein: 218)
              y.fiber = "Acrylic"; y.colorName = "Cobblestone"; y.gramsPerSkein = 100; return y }(),
        ]
        for y in yarns { context.insert(y) }
        try? context.save()
    }
}

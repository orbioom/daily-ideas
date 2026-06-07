import Foundation
import SwiftData

/// Seeds glazes, firings, and pieces so every screen is populated on first run.
enum SampleData {

    static func seed(into context: ModelContext) {
        // Glazes (classic cone-6 recipes, percentages)
        makeGlaze(context, "Clear Gloss", "6", "Glossy", "Oxidation", "Transparent", [
            ("Custer Feldspar", 25, false), ("Silica", 25, false), ("Whiting", 20, false),
            ("EPK Kaolin", 15, false), ("Gerstley Borate", 15, false)
        ])
        makeGlaze(context, "Floating Blue", "6", "Glossy", "Oxidation", "Blue with rust breaks", [
            ("Nepheline Syenite", 48, false), ("Gerstley Borate", 27, false), ("Silica", 20, false),
            ("EPK Kaolin", 5, false), ("Cobalt Carbonate", 1, true), ("Red Iron Oxide", 2, true),
            ("Rutile", 4, true)
        ])
        makeGlaze(context, "Satin White", "6", "Satin", "Oxidation", "Soft opaque white", [
            ("Custer Feldspar", 30, false), ("Dolomite", 22, false), ("EPK Kaolin", 18, false),
            ("Silica", 20, false), ("Whiting", 10, false), ("Tin Oxide", 5, true)
        ])
        makeGlaze(context, "Tenmoku", "10", "Glossy", "Reduction", "Black to amber breaks", [
            ("Custer Feldspar", 53, false), ("Silica", 27, false), ("Whiting", 13, false),
            ("EPK Kaolin", 7, false), ("Red Iron Oxide", 10, true)
        ])

        // Firings
        let bisque = Firing(name: "Bisque #14", date: daysAgo(9), kind: "Bisque",
                            targetCone: "04", atmosphere: "Oxidation")
        bisque.result = "Success"
        bisque.resultNotes = "Even, no cracks."
        context.insert(bisque)
        addSegments(context, bisque, [
            (60, 250, 30), (150, 1000, 0), (200, 1945, 0)
        ])

        let glaze = Firing(name: "Glaze ^6 — Jan", date: daysAgo(3), kind: "Glaze",
                           targetCone: "6", atmosphere: "Oxidation")
        glaze.fastRamp = false
        glaze.result = "Success"
        glaze.resultNotes = "Floating Blue gorgeous. Clear pinholed on one mug — slow the last ramp next time."
        context.insert(glaze)
        addSegments(context, glaze, [
            (200, 250, 20), (400, 1900, 0), (108, 2232, 15), (0, 1900, 0)
        ])

        let planned = Firing(name: "Glaze ^6 — next load", date: daysAgo(-2), kind: "Glaze",
                             targetCone: "6", atmosphere: "Oxidation")
        planned.result = "Planned"
        context.insert(planned)
        addSegments(context, planned, [
            (150, 250, 15), (400, 1900, 0), (108, 2232, 20)
        ])

        // Pieces across stages
        let pieces: [(String, String, String, String, String, Double, Double)] = [
            ("Tall vase", "Speckled Buff", "Wheel", "Glazed", "Floating Blue", 28, 14),
            ("Soup bowls (set of 4)", "Porcelain", "Wheel", "Bisque", "", 8, 16),
            ("Hand-built planter", "Stoneware", "Handbuilt", "Greenware", "", 22, 20),
            ("Espresso cups", "Porcelain", "Wheel", "Fired", "Clear Gloss", 6, 6),
            ("Serving platter", "Speckled Buff", "Slipcast", "Glazed", "Satin White", 4, 34),
            ("Tea bowl", "Stoneware", "Wheel", "Finished", "Tenmoku", 9, 11),
            ("Mug — carved", "Stoneware", "Wheel", "Greenware", "", 11, 9)
        ]
        for p in pieces {
            let piece = Piece(title: p.0, clayBody: p.1, formingMethod: p.2, stage: p.3)
            piece.glazeName = p.4
            piece.heightCm = p.5
            piece.widthCm = p.6
            piece.createdAt = daysAgo(Int.random(in: 4...40))
            piece.updatedAt = daysAgo(Int.random(in: 0...3))
            context.insert(piece)
        }

        try? context.save()
    }

    private static func daysAgo(_ d: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -d, to: Date()) ?? Date()
    }

    private static func makeGlaze(_ ctx: ModelContext, _ name: String, _ cone: String,
                                  _ surface: String, _ atm: String, _ color: String,
                                  _ mats: [(String, Double, Bool)]) {
        let g = Glaze(name: name, coneRange: cone, atmosphere: atm, surface: surface, colorNote: color)
        ctx.insert(g)
        for m in mats {
            let mat = GlazeMaterial(name: m.0, percentage: m.1, isAddition: m.2)
            mat.glaze = g
            ctx.insert(mat)
        }
    }

    private static func addSegments(_ ctx: ModelContext, _ firing: Firing,
                                    _ segs: [(Double, Double, Double)]) {
        for (i, s) in segs.enumerated() {
            let seg = FiringSegment(order: i, rate: s.0, targetTempF: s.1, holdMinutes: s.2)
            seg.firing = firing
            ctx.insert(seg)
        }
    }
}

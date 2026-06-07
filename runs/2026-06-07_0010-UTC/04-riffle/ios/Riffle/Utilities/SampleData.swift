import Foundation
import SwiftData

enum SampleData {
    static func seed(into context: ModelContext) {
        // Patterns with recipes.
        let specs: [(String, FlyType, Int, Int, Int, Int, String, Bool, [(MaterialPart, String, String)])] = [
            ("Adams", .dry, 12, 16, 3, 8, "Mayfly", true, [
                (.hook, "Dry fly hook", "#12–16"), (.thread, "Gray 8/0", ""),
                (.tail, "Grizzly + brown hackle fibers", ""), (.body, "Gray dubbing", ""),
                (.wing, "Grizzly hackle tips", "upright"), (.hackle, "Grizzly + brown", "")]),
            ("Pheasant Tail Nymph", .nymph, 14, 18, 2, 12, "BWO nymph", true, [
                (.hook, "Nymph hook", "#14–18"), (.bead, "Copper bead", "2.0mm"),
                (.thread, "Brown 8/0", ""), (.tail, "Pheasant tail fibers", ""),
                (.body, "Pheasant tail", ""), (.rib, "Copper wire", "")]),
            ("Elk Hair Caddis", .dry, 12, 16, 2, 6, "Caddis", false, [
                (.hook, "Dry fly hook", "#12–16"), (.thread, "Tan 8/0", ""),
                (.body, "Tan dubbing", ""), (.hackle, "Brown, palmered", ""),
                (.wing, "Elk hair", "")]),
            ("Woolly Bugger", .streamer, 6, 10, 1, 5, "Baitfish / leech", true, [
                (.hook, "Streamer hook", "#6–10"), (.bead, "Black cone", ""),
                (.tail, "Black marabou", ""), (.body, "Black chenille", ""),
                (.hackle, "Black, palmered", "")]),
            ("Zebra Midge", .nymph, 18, 22, 1, 14, "Midge pupa", false, [
                (.hook, "Scud hook", "#18–22"), (.bead, "Silver bead", "1.5mm"),
                (.thread, "Black 70D", ""), (.rib, "Silver wire", "")]),
            ("Parachute Adams", .dry, 14, 20, 3, 7, "Mayfly", false, [
                (.hook, "Dry fly hook", "#14–20"), (.thread, "Gray 8/0", ""),
                (.tail, "Hackle fibers", ""), (.body, "Gray dubbing", ""),
                (.wing, "White poly", "post"), (.hackle, "Grizzly", "parachute")]),
            ("Hopper", .terrestrial, 8, 12, 3, 4, "Grasshopper", false, [
                (.hook, "2X long hook", "#8–12"), (.thread, "Tan 6/0", ""),
                (.body, "Tan foam", ""), (.wing, "Elk hair", ""), (.head, "Rubber legs", "")]),
            ("Blue Winged Olive", .dry, 18, 22, 4, 9, "Blue Winged Olive", true, [
                (.hook, "Dry fly hook", "#18–22"), (.thread, "Olive 14/0", ""),
                (.tail, "Blue dun fibers", ""), (.body, "Olive dubbing", ""),
                (.wing, "Dun CDC", ""), (.hackle, "Blue dun", "")])
        ]

        var patterns: [Pattern] = []
        for s in specs {
            let p = Pattern(name: s.0, type: s.1, hookSizeMin: s.2, hookSizeMax: s.3,
                            difficulty: s.4, inStock: s.5, imitates: s.6, isFavorite: s.7)
            context.insert(p)
            for m in s.8 {
                let mat = Material(part: m.0, name: m.1, detail: m.2)
                mat.pattern = p
                p.materials.append(mat)
            }
            patterns.append(p)
        }

        // Catches over the past months.
        let cal = Calendar.current
        let species = ["Brown Trout", "Rainbow Trout", "Brook Trout", "Cutthroat"]
        let waters = ["Madison River", "Spring Creek", "Henrys Fork", "Local tailwater"]
        let weatherOpts: [Weather] = [.sunny, .partly, .overcast, .rain, .mixed]
        for i in 0..<14 {
            let p = patterns[i % patterns.count]
            let c = Catch(
                date: cal.date(byAdding: .day, value: -(i * 9 + 2), to: .now) ?? .now,
                species: species[i % species.count],
                location: waters[i % waters.count],
                lengthInches: Double.random(in: 9...20).rounded(),
                waterTempF: Double(Int.random(in: 48...62)),
                airTempF: Double(Int.random(in: 55...78)),
                weather: weatherOpts[i % weatherOpts.count],
                patternName: p.name,
                released: true,
                notes: i == 0 ? "Best fish of the season on a size 18." : ""
            )
            context.insert(c)
        }

        try? context.save()
    }
}

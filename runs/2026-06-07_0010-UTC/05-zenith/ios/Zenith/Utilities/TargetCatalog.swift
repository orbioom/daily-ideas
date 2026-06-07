import Foundation

/// A famous deep-sky / solar-system target in the reference catalog.
struct SkyTarget: Identifiable {
    let id = UUID()
    let name: String
    let designation: String     // e.g. "M31"
    let type: TargetType
    let constellation: String
    let magnitude: Double
    let sizeArcmin: Double       // apparent size; planets approximate
    let bestMonths: [Int]        // best evening months in N. hemisphere
    let note: String

    func isBest(in month: Int) -> Bool { bestMonths.contains(month) }
}

/// Static showpiece catalog — the objects observers chase by season.
enum TargetCatalog {
    static let all: [SkyTarget] = [
        SkyTarget(name: "Andromeda Galaxy", designation: "M31", type: .galaxy,
                  constellation: "Andromeda", magnitude: 3.4, sizeArcmin: 178,
                  bestMonths: [9,10,11,12], note: "Vast — best at low power with a wide field."),
        SkyTarget(name: "Orion Nebula", designation: "M42", type: .nebula,
                  constellation: "Orion", magnitude: 4.0, sizeArcmin: 85,
                  bestMonths: [12,1,2,3], note: "The winter showpiece; the Trapezium rewards high power."),
        SkyTarget(name: "Pleiades", designation: "M45", type: .cluster,
                  constellation: "Taurus", magnitude: 1.6, sizeArcmin: 110,
                  bestMonths: [11,12,1,2], note: "Best in binoculars or the lowest power you own."),
        SkyTarget(name: "Hercules Cluster", designation: "M13", type: .cluster,
                  constellation: "Hercules", magnitude: 5.8, sizeArcmin: 20,
                  bestMonths: [5,6,7,8], note: "A globe of stars that resolves with aperture."),
        SkyTarget(name: "Ring Nebula", designation: "M57", type: .nebula,
                  constellation: "Lyra", magnitude: 8.8, sizeArcmin: 1.4,
                  bestMonths: [6,7,8,9], note: "Small but bright; takes magnification well."),
        SkyTarget(name: "Whirlpool Galaxy", designation: "M51", type: .galaxy,
                  constellation: "Canes Venatici", magnitude: 8.4, sizeArcmin: 11,
                  bestMonths: [3,4,5,6], note: "Spiral arms appear under dark skies."),
        SkyTarget(name: "Lagoon Nebula", designation: "M8", type: .nebula,
                  constellation: "Sagittarius", magnitude: 6.0, sizeArcmin: 90,
                  bestMonths: [6,7,8], note: "A summer Milky Way gem; a nebula filter helps."),
        SkyTarget(name: "Double Cluster", designation: "NGC 869/884", type: .cluster,
                  constellation: "Perseus", magnitude: 3.7, sizeArcmin: 60,
                  bestMonths: [10,11,12,1], note: "Two clusters in one low-power field."),
        SkyTarget(name: "Albireo", designation: "β Cyg", type: .double,
                  constellation: "Cygnus", magnitude: 3.1, sizeArcmin: 0.5,
                  bestMonths: [7,8,9,10], note: "A gold-and-blue colour-contrast double."),
        SkyTarget(name: "Saturn", designation: "—", type: .planet,
                  constellation: "Ecliptic", magnitude: 0.5, sizeArcmin: 0.3,
                  bestMonths: [8,9,10], note: "Crank up the power — the rings reward it."),
        SkyTarget(name: "Jupiter", designation: "—", type: .planet,
                  constellation: "Ecliptic", magnitude: -2.4, sizeArcmin: 0.7,
                  bestMonths: [11,12,1], note: "Belts and four moons; watch the shadow transits."),
        SkyTarget(name: "The Moon", designation: "—", type: .moon,
                  constellation: "—", magnitude: -12.7, sizeArcmin: 31,
                  bestMonths: Array(1...12), note: "The terminator shows the most detail near first quarter.")
    ]

    static func best(in month: Int) -> [SkyTarget] {
        all.filter { $0.isBest(in: month) }.sorted { $0.magnitude < $1.magnitude }
    }
}

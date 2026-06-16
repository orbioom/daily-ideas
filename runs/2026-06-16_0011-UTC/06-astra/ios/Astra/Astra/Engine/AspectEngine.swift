import Foundation

/// Computes aspects within a single chart and across two charts (synastry).
enum AspectEngine {

    /// All aspects between distinct bodies in one chart, within the given base orb.
    static func aspects(in positions: [BodyPosition], baseOrb: Double) -> [AspectHit] {
        var hits: [AspectHit] = []
        guard positions.count > 1 else { return hits }
        for i in 0..<(positions.count - 1) {
            for j in (i + 1)..<positions.count {
                let a = positions[i]
                let b = positions[j]
                if let hit = classify(a: a, b: b, baseOrb: baseOrb) {
                    hits.append(hit)
                }
            }
        }
        return hits.sorted { $0.orb < $1.orb }
    }

    /// Cross-aspects between two charts' bodies — the heart of synastry.
    static func synastry(_ chartA: [BodyPosition], _ chartB: [BodyPosition], baseOrb: Double) -> [AspectHit] {
        var hits: [AspectHit] = []
        for a in chartA {
            for b in chartB {
                if let hit = classify(a: a, b: b, baseOrb: baseOrb, crossChart: true) {
                    hits.append(hit)
                }
            }
        }
        return hits.sorted { $0.orb < $1.orb }
    }

    /// Test one pair against every aspect angle; return the tightest match within orb.
    private static func classify(a: BodyPosition, b: BodyPosition, baseOrb: Double, crossChart: Bool = false) -> AspectHit? {
        let sep = AstroMath.separation(a.longitude, b.longitude)
        let involvesLuminary = a.planet.isLuminary || b.planet.isLuminary

        var best: AspectHit?
        for kind in AspectKind.allCases {
            let allowedOrb = kind.orb(involvingLuminary: involvesLuminary, base: baseOrb)
            let delta = abs(sep - kind.angle)
            if delta <= allowedOrb {
                // Applying vs separating: compare separation a hair into the future.
                let applying = isApplying(a: a, b: b, target: kind.angle)
                let hit = AspectHit(a: a.planet, b: b.planet, kind: kind, orb: delta, applying: applying)
                if best == nil || delta < (best?.orb ?? .infinity) {
                    best = hit
                }
            }
        }
        return best
    }

    /// Estimate applying/separating: if the faster body is moving toward exact aspect.
    private static func isApplying(a: BodyPosition, b: BodyPosition, target: Double) -> Bool {
        // Heuristic using retrograde flags and which body is generally faster.
        // A separation that will shrink => applying. We approximate motion direction
        // from retrograde state; this is a display nicety, not used in scoring.
        let aFast = speedRank(a.planet) <= speedRank(b.planet)
        let mover = aFast ? a : b
        return !mover.retrograde
    }

    /// Lower = faster mean motion.
    private static func speedRank(_ p: Planet) -> Int {
        switch p {
        case .moon: return 0
        case .mercury: return 1
        case .venus: return 2
        case .sun: return 3
        case .mars: return 4
        case .jupiter: return 5
        case .saturn: return 6
        case .uranus: return 7
        case .neptune: return 8
        case .pluto: return 9
        }
    }
}

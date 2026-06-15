import CoreGraphics
import Foundation

/// Generates and stores all coloring page definitions.
/// Pages are built procedurally from geometric rules so that region counts land
/// in the satisfying 20–120 range with clean, gallery-quality line art.
enum PageLibrary {

    // MARK: - Public catalog

    static let all: [ColoringPage] = buildAll()

    static func page(withID id: String) -> ColoringPage? { byID[id] }

    private static let byID: [String: ColoringPage] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    static func pages(in category: PageCategory) -> [ColoringPage] {
        all.filter { $0.category == category }
    }

    /// Deterministic "page of the day" derived from the calendar date.
    static func dailyPage(for date: Date = Date(), calendar: Calendar = .current) -> ColoringPage {
        guard !all.isEmpty else {
            return ColoringPage(id: "empty", title: "Untitled", category: .geometric,
                                isPremium: false, suggestedPaletteId: PaletteLibrary.default.id, regions: [])
        }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let idx = ((day % all.count) + all.count) % all.count
        return all[idx]
    }

    // MARK: - Catalog assembly

    private static func buildAll() -> [ColoringPage] {
        var pages: [ColoringPage] = []

        // --- Mandalas: rotational wedges × concentric rings ---
        pages.append(makeMandala(id: "mandala-bloom", title: "Lotus Bloom",
                                  wedges: 12, rings: 5, premium: false, paletteId: "blossom"))
        pages.append(makeMandala(id: "mandala-star", title: "Star Mandala",
                                  wedges: 16, rings: 6, premium: true, paletteId: "jewel"))

        // --- Floral: petals arranged radially in layers ---
        pages.append(makeFloral(id: "floral-dahlia", title: "Dahlia",
                                layers: [8, 12, 16], premium: false, paletteId: "ember"))
        pages.append(makeFloral(id: "floral-camellia", title: "Camellia",
                                layers: [6, 10, 14, 18], premium: true, paletteId: "blossom"))

        // --- Geometric: grid subdivided into triangles ---
        pages.append(makeGeometric(id: "geo-prism", title: "Prism Grid",
                                   cols: 5, rows: 5, premium: false, paletteId: "ocean"))
        pages.append(makeGeometric(id: "geo-mosaic", title: "Mosaic",
                                   cols: 6, rows: 5, premium: true, paletteId: "dusk"))

        // --- Landscapes: stacked bands + sun + hills ---
        pages.append(makeLandscape(id: "land-sunset", title: "Sunset Hills",
                                   premium: false, paletteId: "dusk"))
        pages.append(makeLandscape(id: "land-meadow", title: "Rolling Meadow",
                                   premium: true, paletteId: "meadow"))

        // --- Whimsical: a stylized butterfly built from mirrored cells ---
        pages.append(makeButterfly(id: "whimsy-flutter", title: "Flutterby",
                                   premium: true, paletteId: "jewel"))
        pages.append(makeScales(id: "whimsy-scales", title: "Koi Scales",
                                cols: 7, rows: 9, premium: true, paletteId: "ocean"))

        return pages
    }

    // MARK: - Mandala generator

    /// N rotational wedges × M concentric rings; each cell is a quadrilateral region.
    /// Adds a center disc. Region count ≈ wedges*rings + 1.
    private static func makeMandala(id: String, title: String, wedges: Int, rings: Int,
                                    premium: Bool, paletteId: String) -> ColoringPage {
        let center = CGPoint(x: 0.5, y: 0.5)
        let maxR: CGFloat = 0.46
        let innerR: CGFloat = 0.06
        var regions: [Region] = []
        var rid = 0

        // Center disc as a many-sided polygon.
        let discSteps = max(wedges, 12)
        var disc: [CGPoint] = []
        for s in 0..<discSteps {
            let a = (CGFloat(s) / CGFloat(discSteps)) * 2 * .pi
            disc.append(Geometry.polar(center: center, radius: innerR, angle: a))
        }
        regions.append(Region(id: rid, points: disc, suggestedColorIndex: 0)); rid += 1

        let w = max(wedges, 3)
        let r = max(rings, 1)
        for ring in 0..<r {
            let r0 = innerR + (maxR - innerR) * CGFloat(ring) / CGFloat(r)
            let r1 = innerR + (maxR - innerR) * CGFloat(ring + 1) / CGFloat(r)
            for k in 0..<w {
                let a0 = (CGFloat(k) / CGFloat(w)) * 2 * .pi - .pi / 2
                let a1 = (CGFloat(k + 1) / CGFloat(w)) * 2 * .pi - .pi / 2
                let aMid = (a0 + a1) / 2
                // Slightly arc the outer edge by sampling 3 points along each radial arc.
                let p0 = Geometry.polar(center: center, radius: r0, angle: a0)
                let p1 = Geometry.polar(center: center, radius: r0, angle: aMid)
                let p2 = Geometry.polar(center: center, radius: r0, angle: a1)
                let p3 = Geometry.polar(center: center, radius: r1, angle: a1)
                let p4 = Geometry.polar(center: center, radius: r1, angle: aMid)
                let p5 = Geometry.polar(center: center, radius: r1, angle: a0)
                let cell = [p0, p1, p2, p3, p4, p5]
                // Color suggestion alternates per ring + wedge parity for a woven look.
                let idx = (ring * 2 + (k % 3)) % 12
                regions.append(Region(id: rid, points: cell, suggestedColorIndex: idx)); rid += 1
            }
        }
        return ColoringPage(id: id, title: title, category: .mandala,
                            isPremium: premium, suggestedPaletteId: paletteId, regions: regions)
    }

    // MARK: - Floral generator

    /// Concentric layers of petals; each petal is a region. Adds a center.
    private static func makeFloral(id: String, title: String, layers: [Int],
                                   premium: Bool, paletteId: String) -> ColoringPage {
        let center = CGPoint(x: 0.5, y: 0.5)
        var regions: [Region] = []
        var rid = 0

        // Center bud.
        let budSteps = 14
        var bud: [CGPoint] = []
        for s in 0..<budSteps {
            let a = (CGFloat(s) / CGFloat(budSteps)) * 2 * .pi
            bud.append(Geometry.polar(center: center, radius: 0.05, angle: a))
        }
        regions.append(Region(id: rid, points: bud, suggestedColorIndex: 11)); rid += 1

        let baseR: CGFloat = 0.10
        let stepR: CGFloat = 0.115
        for (layerIndex, count) in layers.enumerated() {
            let petals = max(count, 3)
            let rInner = baseR + stepR * CGFloat(layerIndex)
            let rOuter = baseR + stepR * CGFloat(layerIndex + 1) + 0.02
            let width = (CGFloat.pi / CGFloat(petals)) * 0.92
            for k in 0..<petals {
                let center0 = (CGFloat(k) / CGFloat(petals)) * 2 * .pi
                // Build a leaf/petal shape: tip outward, two side curves, base inward.
                let tip = Geometry.polar(center: center, radius: rOuter, angle: center0)
                let baseL = Geometry.polar(center: center, radius: rInner, angle: center0 - width / 2)
                let baseR2 = Geometry.polar(center: center, radius: rInner, angle: center0 + width / 2)
                let midL = Geometry.polar(center: center, radius: (rInner + rOuter) / 2, angle: center0 - width / 2.4)
                let midR = Geometry.polar(center: center, radius: (rInner + rOuter) / 2, angle: center0 + width / 2.4)
                let petal = [baseL, midL, tip, midR, baseR2]
                let idx = (layerIndex * 3 + (k % 2)) % 12
                regions.append(Region(id: rid, points: petal, suggestedColorIndex: idx)); rid += 1
            }
        }
        return ColoringPage(id: id, title: title, category: .floral,
                            isPremium: premium, suggestedPaletteId: paletteId, regions: regions)
    }

    // MARK: - Geometric generator

    /// A grid where each cell is split into 4 triangles meeting at the cell center.
    private static func makeGeometric(id: String, title: String, cols: Int, rows: Int,
                                      premium: Bool, paletteId: String) -> ColoringPage {
        let c = max(cols, 2)
        let r = max(rows, 2)
        let margin: CGFloat = 0.05
        let w = (1 - 2 * margin) / CGFloat(c)
        let h = (1 - 2 * margin) / CGFloat(r)
        var regions: [Region] = []
        var rid = 0
        for row in 0..<r {
            for col in 0..<c {
                let x0 = margin + CGFloat(col) * w
                let y0 = margin + CGFloat(row) * h
                let x1 = x0 + w
                let y1 = y0 + h
                let tl = CGPoint(x: x0, y: y0)
                let tr = CGPoint(x: x1, y: y0)
                let br = CGPoint(x: x1, y: y1)
                let bl = CGPoint(x: x0, y: y1)
                let mid = CGPoint(x: (x0 + x1) / 2, y: (y0 + y1) / 2)
                let tris = [[tl, tr, mid], [tr, br, mid], [br, bl, mid], [bl, tl, mid]]
                for (t, tri) in tris.enumerated() {
                    let idx = ((row + col) * 2 + t) % 12
                    regions.append(Region(id: rid, points: tri, suggestedColorIndex: idx)); rid += 1
                }
            }
        }
        return ColoringPage(id: id, title: title, category: .geometric,
                            isPremium: premium, suggestedPaletteId: paletteId, regions: regions)
    }

    // MARK: - Landscape generator

    /// Stacked sky bands + a sun (disc + halo rings) + layered hills subdivided into segments.
    private static func makeLandscape(id: String, title: String,
                                      premium: Bool, paletteId: String) -> ColoringPage {
        var regions: [Region] = []
        var rid = 0

        // Sky bands (top portion).
        let skyBands = 5
        let skyTop: CGFloat = 0.0
        let skyBottom: CGFloat = 0.5
        for b in 0..<skyBands {
            let y0 = skyTop + (skyBottom - skyTop) * CGFloat(b) / CGFloat(skyBands)
            let y1 = skyTop + (skyBottom - skyTop) * CGFloat(b + 1) / CGFloat(skyBands)
            let band = [CGPoint(x: 0, y: y0), CGPoint(x: 1, y: y0),
                        CGPoint(x: 1, y: y1), CGPoint(x: 0, y: y1)]
            regions.append(Region(id: rid, points: band, suggestedColorIndex: b % 12)); rid += 1
        }

        // Sun: a disc with two halo rings.
        let sun = CGPoint(x: 0.72, y: 0.20)
        let sunRadii: [CGFloat] = [0.06, 0.10, 0.14]
        for (ri, _) in sunRadii.enumerated() {
            let rInner = ri == 0 ? 0 : sunRadii[ri - 1]
            let rOuter = sunRadii[ri]
            let steps = 20
            if ri == 0 {
                var disc: [CGPoint] = []
                for s in 0..<steps {
                    let a = (CGFloat(s) / CGFloat(steps)) * 2 * .pi
                    disc.append(Geometry.polar(center: sun, radius: rOuter, angle: a))
                }
                regions.append(Region(id: rid, points: disc, suggestedColorIndex: 1)); rid += 1
            } else {
                // Ring split into 8 arcs for more coloring detail.
                let arcs = 8
                for k in 0..<arcs {
                    let a0 = (CGFloat(k) / CGFloat(arcs)) * 2 * .pi
                    let a1 = (CGFloat(k + 1) / CGFloat(arcs)) * 2 * .pi
                    let aMid = (a0 + a1) / 2
                    let pts = [
                        Geometry.polar(center: sun, radius: rInner, angle: a0),
                        Geometry.polar(center: sun, radius: rInner, angle: aMid),
                        Geometry.polar(center: sun, radius: rInner, angle: a1),
                        Geometry.polar(center: sun, radius: rOuter, angle: a1),
                        Geometry.polar(center: sun, radius: rOuter, angle: aMid),
                        Geometry.polar(center: sun, radius: rOuter, angle: a0)
                    ]
                    regions.append(Region(id: rid, points: pts, suggestedColorIndex: (2 + k) % 12)); rid += 1
                }
            }
        }

        // Hills: 4 overlapping layers, each subdivided horizontally into segments.
        let hillLayers = 4
        let segs = 8
        for layer in 0..<hillLayers {
            let baseY = 0.45 + CGFloat(layer) * 0.13
            let amp: CGFloat = 0.06 - CGFloat(layer) * 0.008
            let phase = CGFloat(layer) * 1.3
            for s in 0..<segs {
                let x0 = CGFloat(s) / CGFloat(segs)
                let x1 = CGFloat(s + 1) / CGFloat(segs)
                let yTop0 = baseY + amp * sin((x0 * 6.28) + phase)
                let yTop1 = baseY + amp * sin((x1 * 6.28) + phase)
                let pts = [
                    CGPoint(x: x0, y: yTop0),
                    CGPoint(x: x1, y: yTop1),
                    CGPoint(x: x1, y: 1.0),
                    CGPoint(x: x0, y: 1.0)
                ]
                let idx = (6 + layer + (s % 2)) % 12
                regions.append(Region(id: rid, points: pts, suggestedColorIndex: idx)); rid += 1
            }
        }
        return ColoringPage(id: id, title: title, category: .landscape,
                            isPremium: premium, suggestedPaletteId: paletteId, regions: regions)
    }

    // MARK: - Whimsical: butterfly

    /// A symmetric butterfly: body segments + four wings, each wing split into cells.
    private static func makeButterfly(id: String, title: String,
                                      premium: Bool, paletteId: String) -> ColoringPage {
        var regions: [Region] = []
        var rid = 0
        let cx: CGFloat = 0.5

        // Body: stacked oval segments down the center.
        let bodyCount = 6
        for b in 0..<bodyCount {
            let y0 = 0.22 + CGFloat(b) * 0.09
            let y1 = y0 + 0.085
            let halfW: CGFloat = 0.035 - CGFloat(b) * 0.002
            let seg = [
                CGPoint(x: cx - halfW, y: y0),
                CGPoint(x: cx + halfW, y: y0),
                CGPoint(x: cx + halfW, y: y1),
                CGPoint(x: cx - halfW, y: y1)
            ]
            regions.append(Region(id: rid, points: seg, suggestedColorIndex: 5)); rid += 1
        }

        // Wings: for each side and each of upper/lower, a wing outline split into a 3x3 cell grid
        // bounded by the wing ellipse (approximate, but produces pleasing distinct cells).
        let sides: [CGFloat] = [-1, 1]
        for side in sides {
            // Upper wing center & radii.
            let wings: [(center: CGPoint, rx: CGFloat, ry: CGFloat, base: Int)] = [
                (CGPoint(x: cx + side * 0.22, y: 0.32), 0.20, 0.16, 0),
                (CGPoint(x: cx + side * 0.18, y: 0.58), 0.16, 0.14, 3)
            ]
            for wing in wings {
                let gx = 3, gy = 3
                for r in 0..<gy {
                    for c in 0..<gx {
                        // Map grid cell to a wedge of the ellipse via angle + radius bands.
                        let angle0 = CGFloat(c) / CGFloat(gx) * .pi - .pi / 2
                        let angle1 = CGFloat(c + 1) / CGFloat(gx) * .pi - .pi / 2
                        let rad0 = CGFloat(r) / CGFloat(gy)
                        let rad1 = CGFloat(r + 1) / CGFloat(gy)
                        func pt(_ ang: CGFloat, _ rad: CGFloat) -> CGPoint {
                            // side flips the horizontal direction so wings mirror.
                            let dx = side * wing.rx * rad * cos(ang)
                            let dy = wing.ry * rad * sin(ang)
                            return CGPoint(x: wing.center.x + dx, y: wing.center.y + dy)
                        }
                        let cell = [pt(angle0, rad0), pt(angle1, rad0), pt(angle1, rad1), pt(angle0, rad1)]
                        let idx = (wing.base + r + c) % 12
                        regions.append(Region(id: rid, points: cell, suggestedColorIndex: idx)); rid += 1
                    }
                }
            }
        }
        return ColoringPage(id: id, title: title, category: .whimsical,
                            isPremium: premium, suggestedPaletteId: paletteId, regions: regions)
    }

    // MARK: - Whimsical: scales (koi)

    /// Overlapping fish-scale arcs laid out in an offset grid; each scale is one region.
    private static func makeScales(id: String, title: String, cols: Int, rows: Int,
                                   premium: Bool, paletteId: String) -> ColoringPage {
        let c = max(cols, 3)
        let r = max(rows, 3)
        var regions: [Region] = []
        var rid = 0
        let margin: CGFloat = 0.04
        let usable = 1 - 2 * margin
        let stepX = usable / CGFloat(c)
        let stepY = usable / CGFloat(r)
        let radius = stepX * 0.62
        for row in 0..<r {
            let offset = (row % 2 == 0) ? 0 : stepX / 2
            let cy = margin + CGFloat(row) * stepY + stepY / 2
            for col in 0..<c {
                let cx = margin + CGFloat(col) * stepX + stepX / 2 + offset
                if cx + radius > 1 - margin + stepX { continue }
                // A scale = a downward arc (semi-circle-ish fan).
                var pts: [CGPoint] = []
                let steps = 10
                for s in 0...steps {
                    let a = .pi - (CGFloat(s) / CGFloat(steps)) * .pi // pi -> 0, the lower arc
                    pts.append(CGPoint(x: cx + radius * cos(a), y: cy + radius * sin(a) * 1.1))
                }
                // close with the top straight edge
                pts.append(CGPoint(x: cx - radius, y: cy))
                let idx = ((row + col) % 6) + (row % 2) * 6
                regions.append(Region(id: rid, points: pts, suggestedColorIndex: idx % 12)); rid += 1
            }
        }
        return ColoringPage(id: id, title: title, category: .whimsical,
                            isPremium: premium, suggestedPaletteId: paletteId, regions: regions)
    }
}

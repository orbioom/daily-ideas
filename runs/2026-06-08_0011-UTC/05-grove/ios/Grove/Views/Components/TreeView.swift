import SwiftUI

/// A stylised tree that grows with `progress` (0...1). Used live during a focus
/// session and statically in the grove. Withered trees render muted and drooped.
struct TreeView: View {
    var progress: Double          // 0...1 growth
    var species: TreeSpecies
    var withered: Bool = false
    var size: CGFloat = 200

    private var g: Double { max(0.04, min(1, progress)) }

    private var leafColor: Color {
        withered ? Color(hex: 0x9A8F7A) : Color(hex: 0x3E7E5A)
    }
    private var leafColor2: Color {
        withered ? Color(hex: 0x8A8270) : Color(hex: 0x5BA378)
    }
    private var trunkColor: Color {
        withered ? Color(hex: 0x7A6E5C) : Color(hex: 0x6B4F33)
    }

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let baseY = h * 0.95
            let cx = w * 0.5
            let trunkH = h * 0.42 * g
            let trunkW = max(2, w * 0.07 * (0.5 + 0.5 * g))

            // Trunk
            let trunk = Path(roundedRect: CGRect(x: cx - trunkW/2, y: baseY - trunkH,
                                                 width: trunkW, height: trunkH),
                             cornerRadius: trunkW * 0.4)
            ctx.fill(trunk, with: .color(trunkColor))

            // Canopy — clusters depending on species.
            let canopyY = baseY - trunkH
            let scale = g
            let clusters = canopyClusters
            for c in clusters {
                let r = c.r * w * scale
                let cxC = cx + c.dx * w * scale
                let cyC = canopyY + c.dy * h * scale
                let rect = CGRect(x: cxC - r, y: cyC - r, width: r * 2, height: r * 2)
                let droop = withered ? r * 0.25 : 0
                let drect = rect.offsetBy(dx: 0, dy: droop)
                ctx.fill(Path(ellipseIn: drect),
                         with: .color(c.alt ? leafColor2 : leafColor))
            }
        }
        .frame(width: size, height: size)
        .opacity(withered ? 0.7 : 1)
        .accessibilityHidden(true)
    }

    private struct Cluster { let dx: Double; let dy: Double; let r: Double; let alt: Bool }

    private var canopyClusters: [Cluster] {
        switch species {
        case .sprout:
            return [Cluster(dx: 0, dy: -0.04, r: 0.10, alt: false),
                    Cluster(dx: 0.06, dy: -0.02, r: 0.06, alt: true)]
        case .shrub:
            return [Cluster(dx: -0.07, dy: 0, r: 0.11, alt: false),
                    Cluster(dx: 0.07, dy: 0, r: 0.11, alt: true),
                    Cluster(dx: 0, dy: -0.08, r: 0.12, alt: false)]
        case .pine:
            return [Cluster(dx: 0, dy: 0.02, r: 0.15, alt: false),
                    Cluster(dx: 0, dy: -0.08, r: 0.12, alt: true),
                    Cluster(dx: 0, dy: -0.16, r: 0.08, alt: false)]
        case .oak:
            return [Cluster(dx: -0.10, dy: -0.02, r: 0.13, alt: false),
                    Cluster(dx: 0.10, dy: -0.02, r: 0.13, alt: true),
                    Cluster(dx: 0, dy: -0.12, r: 0.16, alt: false),
                    Cluster(dx: 0, dy: 0.02, r: 0.11, alt: true)]
        case .redwood:
            return [Cluster(dx: 0, dy: 0.04, r: 0.17, alt: false),
                    Cluster(dx: -0.06, dy: -0.06, r: 0.13, alt: true),
                    Cluster(dx: 0.06, dy: -0.06, r: 0.13, alt: false),
                    Cluster(dx: 0, dy: -0.16, r: 0.12, alt: true),
                    Cluster(dx: 0, dy: -0.24, r: 0.08, alt: false)]
        }
    }
}

struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Brand.mono(20, weight: .semibold)).foregroundStyle(tint)
                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

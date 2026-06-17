import SwiftUI

/// Pure rendering engine. Draws a `WallpaperSpec` into a SwiftUI `GraphicsContext`
/// (for live preview & grid thumbnails) and rasterizes a high-resolution `UIImage`
/// for export. Every division is guarded and every array access is bounds-safe.
enum WallpaperRenderer {

    // MARK: - Canvas drawing (preview + thumbnails)

    static func draw(_ spec: WallpaperSpec, in context: inout GraphicsContext, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let colors = spec.colors
        guard !colors.isEmpty else { return }

        // The base style art is drawn inside a layer so any softness blur applies
        // to the whole composition. Grain & vignette are drawn afterwards, unblurred.
        let extraBlur = styleBaseBlur(spec.style)
        let blurRadius = (spec.blur + extraBlur) * size.width * 0.06

        context.drawLayer { layer in
            if blurRadius > 0.5 {
                layer.addFilter(.blur(radius: blurRadius))
            }
            switch spec.style {
            case .linearGradient: drawLinear(spec, colors: colors, in: &layer, size: size)
            case .meshGradient: drawMesh(spec, colors: colors, in: &layer, size: size)
            case .lowPoly: drawLowPoly(spec, colors: colors, in: &layer, size: size)
            case .stripes: drawStripes(spec, colors: colors, in: &layer, size: size)
            case .dotField: drawDotField(spec, colors: colors, in: &layer, size: size)
            case .aurora: drawAurora(spec, colors: colors, in: &layer, size: size)
            case .quote: drawQuote(spec, colors: colors, in: &layer, size: size)
            }
        }

        if spec.grain > 0.001 { drawGrain(spec, in: &context, size: size) }
        if spec.vignette > 0.001 { drawVignette(amount: spec.vignette, in: &context, size: size) }
    }

    /// Some styles read better with a baseline softness (mesh, aurora are intentionally dreamy).
    private static func styleBaseBlur(_ style: WallpaperStyle) -> Double {
        switch style {
        case .meshGradient: return 0.5
        case .aurora: return 0.45
        default: return 0
        }
    }

    // MARK: - High-resolution export

    @MainActor
    static func renderImage(_ spec: WallpaperSpec, size: CGSize, scale: CGFloat = 1) -> UIImage? {
        let view = WallpaperCanvasView(spec: spec)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    // MARK: - Geometry helpers

    private static func angleUnitVector(_ degrees: Double) -> (CGFloat, CGFloat) {
        let radians = degrees * .pi / 180
        return (CGFloat(cos(radians)), CGFloat(sin(radians)))
    }

    private static func gradientPoints(angle: Double, size: CGSize) -> (UnitPoint, UnitPoint) {
        let (dx, dy) = angleUnitVector(angle)
        let start = UnitPoint(x: 0.5 - Double(dx) * 0.5, y: 0.5 - Double(dy) * 0.5)
        let end = UnitPoint(x: 0.5 + Double(dx) * 0.5, y: 0.5 + Double(dy) * 0.5)
        return (start, end)
    }

    /// Interpolate within an array of colors at parameter t in [0, 1].
    private static func sample(_ colors: [Color], at t: Double) -> Color {
        guard let first = colors.first else { return Theme.accent }
        guard colors.count > 1 else { return first }
        let clamped = t.clamped(to: 0...1)
        let scaled = clamped * Double(colors.count - 1)
        let lower = Int(scaled.rounded(.down)).clamped(to: 0...(colors.count - 1))
        let upper = (lower + 1).clamped(to: 0...(colors.count - 1))
        let frac = scaled - Double(lower)
        let a = colors[safe: lower] ?? first
        let b = colors[safe: upper] ?? first
        return blend(a, b, frac)
    }

    private static func blend(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ca = UIColor(a)
        let cb = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ca.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        cb.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(t.clamped(to: 0...1))
        return Color(
            .sRGB,
            red: Double(r1 + (r2 - r1) * f),
            green: Double(g1 + (g2 - g1) * f),
            blue: Double(b1 + (b2 - b1) * f),
            opacity: Double(a1 + (a2 - a1) * f)
        )
    }

    // MARK: - Styles

    private static func drawLinear(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        let (start, end) = gradientPoints(angle: spec.angle, size: size)
        let rect = CGRect(origin: .zero, size: size)
        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(colors: colors),
            startPoint: CGPoint(x: start.x * size.width, y: start.y * size.height),
            endPoint: CGPoint(x: end.x * size.width, y: end.y * size.height)
        )
        context.fill(Path(rect), with: shading)
    }

    private static func drawMesh(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        var rng = SplitMix64(seed: spec.seed)
        // Base fill.
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(sample(colors, at: 1)))
        // Several soft radial blooms positioned by the seed.
        let blooms = 3 + (colors.count.clamped(to: 1...5))
        for i in 0..<blooms {
            let cx = rng.double(in: 0.1...0.9) * size.width
            let cy = rng.double(in: 0.1...0.9) * size.height
            let radius = rng.double(in: 0.3...0.8) * max(size.width, size.height)
            let color = sample(colors, at: Double(i) / Double(max(blooms - 1, 1)))
            let shading = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [color.opacity(0.9), color.opacity(0)]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: radius
            )
            context.fill(Path(CGRect(origin: .zero, size: size)), with: shading)
        }
    }

    private static func drawLowPoly(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        // Underlying gradient so the facets read as one image.
        let (start, end) = gradientPoints(angle: 90, size: size)
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: colors),
                startPoint: CGPoint(x: start.x * size.width, y: start.y * size.height),
                endPoint: CGPoint(x: end.x * size.width, y: end.y * size.height)
            )
        )
        var rng = SplitMix64(seed: spec.seed)
        let cols = spec.complexity.clamped(to: 2...14)
        let rows = max(2, Int((Double(cols) * size.height / max(size.width, 1)).rounded()))
        let cellW = size.width / CGFloat(cols)
        let cellH = size.height / CGFloat(rows)
        let jitter = 0.42

        // Build a jittered point grid.
        func point(_ c: Int, _ r: Int) -> CGPoint {
            let baseX = CGFloat(c) * cellW
            let baseY = CGFloat(r) * cellH
            // Edges stay pinned so the canvas is fully covered.
            let jx = (c == 0 || c == cols) ? 0 : rng.jitter(jitter) * Double(cellW)
            let jy = (r == 0 || r == rows) ? 0 : rng.jitter(jitter) * Double(cellH)
            return CGPoint(x: baseX + CGFloat(jx), y: baseY + CGFloat(jy))
        }

        var grid: [[CGPoint]] = []
        for r in 0...rows {
            var rowPts: [CGPoint] = []
            for c in 0...cols { rowPts.append(point(c, r)) }
            grid.append(rowPts)
        }

        for r in 0..<rows {
            for c in 0..<cols {
                guard
                    let topLeft = grid[safe: r]?[safe: c],
                    let topRight = grid[safe: r]?[safe: c + 1],
                    let bottomLeft = grid[safe: r + 1]?[safe: c],
                    let bottomRight = grid[safe: r + 1]?[safe: c + 1]
                else { continue }

                let t1 = (Double(c) / Double(cols) + Double(r) / Double(rows)) / 2
                let c1 = sample(colors, at: (t1 + rng.jitter(0.06)).clamped(to: 0...1))
                let c2 = sample(colors, at: (t1 + rng.jitter(0.12)).clamped(to: 0...1))

                var triA = Path()
                triA.move(to: topLeft)
                triA.addLine(to: topRight)
                triA.addLine(to: bottomLeft)
                triA.closeSubpath()
                context.fill(triA, with: .color(c1))

                var triB = Path()
                triB.move(to: topRight)
                triB.addLine(to: bottomRight)
                triB.addLine(to: bottomLeft)
                triB.closeSubpath()
                context.fill(triB, with: .color(c2))
            }
        }
    }

    private static func drawStripes(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        // Gradient base for depth.
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(sample(colors, at: 0)))
        let count = spec.complexity.clamped(to: 2...40)
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        let stripeW = diagonal / CGFloat(count)
        let radians = spec.angle * .pi / 180

        context.drawLayer { layer in
            layer.translateBy(x: size.width / 2, y: size.height / 2)
            layer.rotate(by: .radians(radians))
            layer.translateBy(x: -diagonal / 2, y: -diagonal / 2)
            for i in 0..<count {
                let x = CGFloat(i) * stripeW
                let rect = CGRect(x: x, y: 0, width: stripeW, height: diagonal)
                let color = sample(colors, at: Double(i) / Double(max(count - 1, 1)))
                layer.fill(Path(rect), with: .color(color))
            }
        }
    }

    private static func drawDotField(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        // Tinted base gradient.
        let (start, end) = gradientPoints(angle: 120, size: size)
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: colors),
                startPoint: CGPoint(x: start.x * size.width, y: start.y * size.height),
                endPoint: CGPoint(x: end.x * size.width, y: end.y * size.height)
            )
        )
        var rng = SplitMix64(seed: spec.seed)
        let cols = spec.complexity.clamped(to: 3...22)
        let spacing = size.width / CGFloat(cols)
        guard spacing > 0 else { return }
        let rows = max(1, Int((size.height / spacing).rounded(.up)))
        let highlight = colors.count > 1 ? sample(colors, at: 1) : Color.white
        for r in 0...rows {
            for c in 0...cols {
                let cx = CGFloat(c) * spacing + spacing / 2
                let cy = CGFloat(r) * spacing + spacing / 2
                let radius = spacing * CGFloat(rng.double(in: 0.08...0.34))
                let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
                let opacity = rng.double(in: 0.12...0.7)
                context.fill(Path(ellipseIn: rect), with: .color(highlight.opacity(opacity)))
            }
        }
    }

    private static func drawAurora(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        // Deep base.
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(sample(colors, at: 0)))
        var rng = SplitMix64(seed: spec.seed)
        let bands = spec.complexity.clamped(to: 2...8)
        let radians = spec.angle * .pi / 180

        context.drawLayer { layer in
            layer.translateBy(x: size.width / 2, y: size.height / 2)
            layer.rotate(by: .radians(radians * 0.3))
            layer.translateBy(x: -size.width / 2, y: -size.height / 2)
            for b in 0..<bands {
                let phase = rng.double(in: 0...(2 * .pi))
                let amplitude = rng.double(in: 0.06...0.2) * Double(size.height)
                let frequency = rng.double(in: 1.2...3.2)
                let baseY = (Double(b) + 0.5) / Double(bands) * Double(size.height)
                let thickness = rng.double(in: 0.1...0.26) * Double(size.height)
                let color = sample(colors, at: Double(b) / Double(max(bands - 1, 1)))

                var path = Path()
                let steps = 48
                path.move(to: CGPoint(x: 0, y: baseY))
                for s in 0...steps {
                    let x = Double(s) / Double(steps) * Double(size.width)
                    let y = baseY + sin(x / Double(size.width) * .pi * frequency + phase) * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                for s in stride(from: steps, through: 0, by: -1) {
                    let x = Double(s) / Double(steps) * Double(size.width)
                    let y = baseY + thickness + sin(x / Double(size.width) * .pi * frequency + phase) * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.closeSubpath()
                layer.fill(path, with: .color(color.opacity(0.55)))
            }
        }
    }

    private static func drawQuote(_ spec: WallpaperSpec, colors: [Color], in context: inout GraphicsContext, size: CGSize) {
        let (start, end) = gradientPoints(angle: spec.angle, size: size)
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: colors),
                startPoint: CGPoint(x: start.x * size.width, y: start.y * size.height),
                endPoint: CGPoint(x: end.x * size.width, y: end.y * size.height)
            )
        )
        // Soft scrim for legibility.
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.28)]),
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.7
            )
        )
        let text = (spec.quoteText?.isEmpty == false) ? (spec.quoteText ?? "") : "Create boldly."
        let fontSize = size.width * 0.085
        var resolved = context.resolve(
            Text(text)
                .font(.system(size: fontSize, weight: spec.quoteWeight, design: .rounded))
                .foregroundStyle(Color.white)
        )
        resolved.shading = .color(.white)
        let textWidth = size.width * 0.78
        context.draw(
            resolved,
            in: CGRect(x: (size.width - textWidth) / 2, y: 0, width: textWidth, height: size.height)
        )
    }

    // MARK: - Post effects

    private static func drawGrain(_ spec: WallpaperSpec, in context: inout GraphicsContext, size: CGSize) {
        var rng = SplitMix64(seed: spec.seed ^ 0xA5A5A5A5)
        // Density scales with the requested amount; capped for performance.
        let area = size.width * size.height
        let density = (spec.grain.clamped(to: 0...1)) * 0.0009
        let count = min(9000, max(0, Int(area * density)))
        guard count > 0 else { return }
        for _ in 0..<count {
            let x = rng.double(in: 0...Double(size.width))
            let y = rng.double(in: 0...Double(size.height))
            let bright = rng.unit() > 0.5
            let alpha = rng.double(in: 0.04...0.16) * spec.grain
            let s = rng.double(in: 0.6...1.6)
            let rect = CGRect(x: x, y: y, width: s, height: s)
            context.fill(Path(rect), with: .color((bright ? Color.white : Color.black).opacity(alpha)))
        }
    }

    private static func drawVignette(amount: Double, in context: inout GraphicsContext, size: CGSize) {
        let strength = amount.clamped(to: 0...1)
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(stops: [
                .init(color: .black.opacity(0), location: 0.55),
                .init(color: .black.opacity(0.65 * strength), location: 1.0)
            ]),
            center: CGPoint(x: size.width / 2, y: size.height / 2),
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.72
        )
        context.fill(Path(CGRect(origin: .zero, size: size)), with: shading)
    }
}

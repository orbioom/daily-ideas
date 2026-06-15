import SwiftUI

/// The shareable poster rendered by `ImageRenderer`. A fixed-size, self-contained view:
/// title, the full week grid drawn with a Canvas, a one-line reflection, and the legend.
/// Uses explicit dark colors so the exported image looks intentional regardless of the
/// device appearance at render time.
struct PosterView: View {
    let profile: LifeProfile
    let model: GridModel
    let stats: LifeStats
    let dotStyle: DotStyle

    // Fixed poster palette (independent of colorScheme so the image is deterministic).
    private let bg = Color(hexString: "0B0D14")
    private let ink = Color(hexString: "F3F1EA")
    private let inkSoft = Color(hexString: "AAB0C2")
    private let accent = Color(hexString: "E8A84B")
    private let pastTone = Color(hexString: "C9CDDA")
    private let futureTone = Color(hexString: "262C3D")

    private let posterWidth: CGFloat = 1080
    private let posterHeight: CGFloat = 1500

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text((profile.name?.isEmpty == false ? profile.name! : "A life").uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                Text("in weeks")
                    .font(.system(size: 64, weight: .semibold, design: .serif))
                    .foregroundStyle(ink)
            }

            posterGrid
                .frame(height: posterHeight - 560)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(Fmt.grouped(stats.weeksLived)) weeks lived · \(Fmt.grouped(stats.weeksRemaining)) ahead · \(Fmt.oneDecimal(stats.percentLived))% of an expected \(profile.lifeExpectancyYears) years")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 28) {
                swatch(accent, "Now")
                swatch(pastTone, "Lived")
                swatch(futureTone, "Ahead")
                Spacer()
                Text("Span")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
        }
        .padding(64)
        .frame(width: posterWidth, height: posterHeight, alignment: .topLeading)
        .background(bg)
    }

    private var posterGrid: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                drawGrid(in: &ctx, size: size)
            }
        }
    }

    private func drawGrid(in ctx: inout GraphicsContext, size: CGSize) {
        let cols = CGFloat(model.columns)
        let rows = CGFloat(model.rows)
        let spacingRatio: CGFloat = 0.34
        // Solve dot size so cols*dot + (cols-1)*dot*ratio == width.
        let dot = size.width / (cols + (cols - 1) * spacingRatio)
        let spacing = dot * spacingRatio
        let usedHeight = rows * dot + (rows - 1) * spacing
        let originY = max((size.height - usedHeight) / 2, 0)

        for index in 0..<model.totalWeeks {
            let row = index / model.columns
            let col = index % model.columns
            let x = CGFloat(col) * (dot + spacing)
            let y = originY + CGFloat(row) * (dot + spacing)
            let rect = CGRect(x: x, y: y, width: dot, height: dot)
            let radius = dotStyle.cornerRadius(for: dot)
            let path = Path(roundedRect: rect, cornerRadius: radius)

            let isCurrent = index == model.currentIndex
            let isFuture = index > model.currentIndex
            let fill: Color
            if isCurrent {
                fill = accent
            } else if let c = model.chapterColor(at: index) {
                fill = isFuture ? c.opacity(0.32) : c
            } else {
                fill = isFuture ? futureTone : pastTone
            }
            ctx.fill(path, with: .color(fill))

            if isCurrent {
                let ringRect = rect.insetBy(dx: -dot * 0.55, dy: -dot * 0.55)
                ctx.stroke(Path(roundedRect: ringRect, cornerRadius: dotStyle.cornerRadius(for: ringRect.width)),
                           with: .color(accent.opacity(0.7)),
                           lineWidth: max(dot * 0.2, 1))
            }
        }
    }

    private func swatch(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 18, height: 18)
            Text(label)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(inkSoft)
        }
    }
}

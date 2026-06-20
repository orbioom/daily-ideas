import SwiftUI

struct BubbleGridView: View {
    let game: OrbGame
    let colorBlindMode: Bool
    let showAimLine: Bool
    @State private var popScale: [GridPos: CGFloat] = [:]

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let colW = geo.size.width / CGFloat(BubbleGrid.cols)
            let rowH = colW * 0.45 * 1.8
            let radius = colW * 0.43

            Canvas { context, size in
                // Draw subtle background grid hint dots
                for r in 0..<BubbleGrid.rows {
                    for c in 0..<BubbleGrid.cols {
                        let offset = r % 2 == 1 ? colW * 0.5 : 0
                        let cx = offset + CGFloat(c) * colW + colW / 2
                        let cy = CGFloat(r) * rowH + rowH / 2
                        let dotRect = CGRect(
                            x: cx - radius * 0.08,
                            y: cy - radius * 0.08,
                            width: radius * 0.16,
                            height: radius * 0.16
                        )
                        context.fill(Path(ellipseIn: dotRect), with: .color(Color.white.opacity(0.04)))
                    }
                }

                // Draw bubbles
                for r in 0..<BubbleGrid.rows {
                    for c in 0..<BubbleGrid.cols {
                        guard let bubble = game.grid.cells[r][c] else { continue }
                        let pos = GridPos(row: r, col: c)
                        let offset = r % 2 == 1 ? colW * 0.5 : 0
                        let cx = offset + CGFloat(c) * colW + colW / 2
                        let cy = CGFloat(r) * rowH + rowH / 2

                        let scale = popScale[pos] ?? 1.0
                        let displayRadius = radius * scale

                        let baseColor = bubble.color.displayColor(colorBlind: colorBlindMode)
                        let bubbleRect = CGRect(
                            x: cx - displayRadius,
                            y: cy - displayRadius,
                            width: displayRadius * 2,
                            height: displayRadius * 2
                        )

                        // Drop shadow
                        let shadowRect = bubbleRect.insetBy(dx: 2, dy: 2).offsetBy(dx: 2, dy: 3)
                        context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.3)))

                        // Main bubble fill
                        context.fill(Path(ellipseIn: bubbleRect), with: .color(baseColor))

                        // Large highlight (top-left shine)
                        let shineRect = CGRect(
                            x: cx - displayRadius * 0.6,
                            y: cy - displayRadius * 0.7,
                            width: displayRadius * 0.7,
                            height: displayRadius * 0.6
                        )
                        context.fill(Path(ellipseIn: shineRect), with: .color(Color.white.opacity(0.4)))

                        // Small specular highlight
                        let specRect = CGRect(
                            x: cx - displayRadius * 0.35,
                            y: cy - displayRadius * 0.55,
                            width: displayRadius * 0.25,
                            height: displayRadius * 0.2
                        )
                        context.fill(Path(ellipseIn: specRect), with: .color(Color.white.opacity(0.7)))

                        // Bottom darkening for 3D depth
                        let darkRect = CGRect(
                            x: cx - displayRadius * 0.5,
                            y: cy + displayRadius * 0.4,
                            width: displayRadius,
                            height: displayRadius * 0.45
                        )
                        context.fill(Path(ellipseIn: darkRect), with: .color(Color.black.opacity(0.2)))

                        // Outline stroke
                        context.stroke(
                            Path(ellipseIn: bubbleRect),
                            with: .color(Color.white.opacity(0.15)),
                            lineWidth: 0.8
                        )
                    }
                }

                // Draw aim trajectory line when playing
                if showAimLine && game.phase == .playing {
                    let shooterY = geo.size.height + 60.0
                    let startPt = CGPoint(x: geo.size.width / 2, y: shooterY)
                    let trajectory = game.aimTrajectory(from: startPt, in: rect)

                    var aimPath = Path()
                    var dotCount = 0
                    var lastDotPoint: CGPoint? = nil

                    for (i, pt) in trajectory.enumerated() {
                        if i == 0 {
                            lastDotPoint = pt
                            continue
                        }
                        if let last = lastDotPoint {
                            let dist = sqrt(pow(pt.x - last.x, 2) + pow(pt.y - last.y, 2))
                            if dist > 18 {
                                aimPath.move(to: last)
                                aimPath.addLine(to: pt)
                                lastDotPoint = pt
                                dotCount += 1
                                if dotCount > 25 { break }
                            }
                        }
                    }

                    context.stroke(
                        aimPath,
                        with: .color(Color.white.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 2.5, dash: [6, 10])
                    )
                }
            }
            .onChange(of: game.poppedPositions) { _, newPositions in
                if !newPositions.isEmpty {
                    animatePop(positions: newPositions)
                }
            }
        }
        .background(OrbTheme.surface.opacity(0.3))
        .cornerRadius(12)
    }

    private func animatePop(positions: Set<GridPos>) {
        for pos in positions {
            popScale[pos] = 1.3
        }
        withAnimation(.spring(duration: 0.15)) {
            for pos in positions {
                popScale[pos] = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            for pos in positions {
                popScale.removeValue(forKey: pos)
            }
        }
    }
}

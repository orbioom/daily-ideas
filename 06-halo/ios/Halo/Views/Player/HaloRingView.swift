import SwiftUI

struct HaloRingView: View {
    let color: Color
    let isPlaying: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse: Bool = false

    var body: some View {
        TimelineView(.animation(paused: !isPlaying || reduceMotion)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius = min(size.width, size.height) * 0.38

                // Outer glow rings
                for i in 0..<4 {
                    let layerRadius = baseRadius + CGFloat(i) * 8 + (pulse ? CGFloat(i) * 4 : 0)
                    let opacity = 0.15 - Double(i) * 0.03
                    let path = Path { p in
                        p.addEllipse(in: CGRect(
                            x: center.x - layerRadius,
                            y: center.y - layerRadius,
                            width: layerRadius * 2,
                            height: layerRadius * 2
                        ))
                    }
                    context.stroke(
                        path,
                        with: .color(color.opacity(opacity)),
                        lineWidth: CGFloat(12 - i * 2)
                    )
                }

                // Main ring
                let mainPath = Path { p in
                    p.addEllipse(in: CGRect(
                        x: center.x - baseRadius,
                        y: center.y - baseRadius,
                        width: baseRadius * 2,
                        height: baseRadius * 2
                    ))
                }
                context.stroke(
                    mainPath,
                    with: .color(color.opacity(0.85)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )

                // Inner fill
                let innerRadius = baseRadius * 0.75
                let innerPath = Path { p in
                    p.addEllipse(in: CGRect(
                        x: center.x - innerRadius,
                        y: center.y - innerRadius,
                        width: innerRadius * 2,
                        height: innerRadius * 2
                    ))
                }
                context.fill(innerPath, with: .color(color.opacity(0.05)))

                // Shimmer dots on the ring
                if isPlaying && !reduceMotion {
                    let dotCount = 8
                    let date = timeline.date.timeIntervalSinceReferenceDate
                    for i in 0..<dotCount {
                        let angle = (Double(i) / Double(dotCount)) * 2 * Double.pi
                            + date * 0.3
                        let x = center.x + cos(angle) * baseRadius
                        let y = center.y + sin(angle) * baseRadius
                        let dotPath = Path { p in
                            p.addEllipse(in: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5))
                        }
                        let dotOpacity = (sin(angle * 2 + date) + 1) * 0.25 + 0.1
                        context.fill(dotPath, with: .color(color.opacity(dotOpacity)))
                    }
                }
            }
        }
        .onAppear {
            if !reduceMotion && isPlaying {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing && !reduceMotion {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    pulse = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0D0D1A").ignoresSafeArea()
        HaloRingView(color: Color(hex: "#C084FC"), isPlaying: true)
            .frame(width: 280, height: 280)
    }
}

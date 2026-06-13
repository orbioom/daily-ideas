import SwiftUI
import Foundation

/// A pointy-top regular hexagon, sized to fill its frame.
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        var path = Path()
        // Pointy-top hexagon: vertices every 60°, starting at the top point.
        for i in 0..<6 {
            let angle = (Double(i) * 60.0 - 90.0) * .pi / 180.0
            let p = CGPoint(x: cx + (w / 2) * CGFloat(cos(angle)),
                            y: cy + (h / 2) * CGFloat(sin(angle)))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

/// One tappable letter cell. The centre cell is gold; outer cells are calm.
struct HexCell: View {
    let letter: Character
    let isCenter: Bool
    let size: CGFloat
    var simple: Bool = false
    let action: () -> Void

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fill: Color { isCenter ? Theme.accent : Theme.hexOuter }
    private var textColor: Color { isCenter ? .white : Theme.ink }

    var body: some View {
        Button(action: action) {
            ZStack {
                if simple {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isCenter ? Color.clear : Theme.hairline, lineWidth: 1)
                } else {
                    Hexagon().fill(fill)
                    Hexagon().stroke(isCenter ? Color.clear : Theme.hairline, lineWidth: 1)
                }
                Text(String(letter).uppercased())
                    .font(Theme.rounded(size * 0.42, .heavy))
                    .foregroundStyle(textColor)
            }
            .frame(width: size, height: size)
            .scaleEffect(pressed && !reduceMotion ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { pressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = false } }
        )
        .accessibilityLabel(isCenter ? "Centre letter \(String(letter).uppercased())"
                                     : "Letter \(String(letter).uppercased())")
        .accessibilityHint("Adds this letter to your word")
    }
}

/// The signature board: a centre hex ringed by six outer hexes. The outer ring
/// order is supplied by the caller so Shuffle can reorder it.
struct HoneycombView: View {
    let center: Character
    let outer: [Character]      // exactly six, in display order
    var simple: Bool = false
    let onTap: (Character) -> Void

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width / 3.05, geo.size.height / 3.4)
            // Geometry for a flat honeycomb of pointy-top hexes.
            let dx = cell * 0.92          // horizontal step to a ring cell
            let dy = cell * 0.80          // vertical step to a ring cell
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            // Six ring positions, clockwise from top.
            let ring: [CGPoint] = [
                CGPoint(x: cx,        y: cy - dy * 2),
                CGPoint(x: cx + dx,   y: cy - dy),
                CGPoint(x: cx + dx,   y: cy + dy),
                CGPoint(x: cx,        y: cy + dy * 2),
                CGPoint(x: cx - dx,   y: cy + dy),
                CGPoint(x: cx - dx,   y: cy - dy)
            ]
            ZStack {
                ForEach(Array(outer.enumerated()), id: \.offset) { idx, ch in
                    let p = idx < ring.count ? ring[idx] : CGPoint(x: cx, y: cy)
                    HexCell(letter: ch, isCenter: false, size: cell, simple: simple) {
                        onTap(ch)
                    }
                    .position(p)
                }
                HexCell(letter: center, isCenter: true, size: cell, simple: simple) {
                    onTap(center)
                }
                .position(x: cx, y: cy)
            }
        }
        .aspectRatio(0.92, contentMode: .fit)
        .accessibilityElement(children: .contain)
    }
}

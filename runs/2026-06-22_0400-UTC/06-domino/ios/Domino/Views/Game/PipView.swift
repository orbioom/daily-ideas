import SwiftUI

struct PipView: View {
    let value: Int
    let pipColor: Color
    let size: CGFloat

    private var pipRadius: CGFloat { size * 0.10 }

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let r = min(w, h) * 0.10
            let positions = pipPositions(value: value, width: w, height: h)
            for pos in positions {
                let rect = CGRect(
                    x: pos.x - r,
                    y: pos.y - r,
                    width: r * 2,
                    height: r * 2
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(pipColor)
                )
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(value) pips")
    }

    private func pipPositions(value: Int, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let w = width
        let h = height
        let cx = w / 2
        let cy = h / 2
        let mx = w * 0.28
        let my = h * 0.28

        switch value {
        case 0:
            return []
        case 1:
            return [CGPoint(x: cx, y: cy)]
        case 2:
            return [
                CGPoint(x: cx + mx, y: cy - my),
                CGPoint(x: cx - mx, y: cy + my)
            ]
        case 3:
            return [
                CGPoint(x: cx + mx, y: cy - my),
                CGPoint(x: cx, y: cy),
                CGPoint(x: cx - mx, y: cy + my)
            ]
        case 4:
            return [
                CGPoint(x: cx - mx, y: cy - my),
                CGPoint(x: cx + mx, y: cy - my),
                CGPoint(x: cx - mx, y: cy + my),
                CGPoint(x: cx + mx, y: cy + my)
            ]
        case 5:
            return [
                CGPoint(x: cx - mx, y: cy - my),
                CGPoint(x: cx + mx, y: cy - my),
                CGPoint(x: cx, y: cy),
                CGPoint(x: cx - mx, y: cy + my),
                CGPoint(x: cx + mx, y: cy + my)
            ]
        case 6:
            return [
                CGPoint(x: cx - mx, y: cy - my),
                CGPoint(x: cx + mx, y: cy - my),
                CGPoint(x: cx - mx, y: cy),
                CGPoint(x: cx + mx, y: cy),
                CGPoint(x: cx - mx, y: cy + my),
                CGPoint(x: cx + mx, y: cy + my)
            ]
        default:
            return []
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(0...6, id: \.self) { v in
            PipView(value: v, pipColor: .black, size: 40)
                .background(Color(red: 0.96, green: 0.94, blue: 0.88))
                .cornerRadius(4)
        }
    }
    .padding()
    .background(DominoTheme.mahogany)
}

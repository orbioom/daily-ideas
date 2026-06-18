import SwiftUI

/// A flat-top regular hexagon, sized to its bounding rect.
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        let radius = min(w, h) / 2
        var path = Path()
        for i in 0..<6 {
            // Flat-top hexagon: start at 0 degrees and step 60°.
            let angle = Double(i) * (.pi / 3.0)
            let x = cx + radius * cos(angle)
            let y = cy + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

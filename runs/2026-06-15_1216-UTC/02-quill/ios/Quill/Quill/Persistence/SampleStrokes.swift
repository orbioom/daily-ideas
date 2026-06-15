import PencilKit
import UIKit

/// Programmatically builds simple `PKDrawing`s for seed pages so the Library
/// isn't empty on first launch. Strokes are deterministic and low-risk.
enum SampleStrokes {
    /// Build a `PKStroke` from a list of points with a given ink and width.
    private static func stroke(
        points: [CGPoint],
        ink: PKInk,
        width: CGFloat
    ) -> PKStroke {
        let controlPoints = points.map { pt in
            PKStrokePoint(
                location: pt,
                timeOffset: 0,
                size: CGSize(width: width, height: width),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
        return PKStroke(ink: ink, path: path)
    }

    /// A short handwritten-looking title scribble plus a couple of underlines.
    static func titleSketch(color: UIColor) -> Data {
        let pen = PKInk(.pen, color: color)
        let marker = PKInk(.marker, color: color.withAlphaComponent(0.5))
        var strokes: [PKStroke] = []

        // Wavy "title" line
        var wave: [CGPoint] = []
        for i in 0...40 {
            let x = 120 + CGFloat(i) * 16
            let y = 180 + sin(CGFloat(i) * 0.6) * 22
            wave.append(CGPoint(x: x, y: y))
        }
        strokes.append(stroke(points: wave, ink: pen, width: 5))

        // Two body lines
        strokes.append(stroke(
            points: [CGPoint(x: 120, y: 300), CGPoint(x: 760, y: 300)],
            ink: pen, width: 3))
        strokes.append(stroke(
            points: [CGPoint(x: 120, y: 360), CGPoint(x: 620, y: 360)],
            ink: pen, width: 3))

        // Highlighter sweep
        strokes.append(stroke(
            points: [CGPoint(x: 120, y: 240), CGPoint(x: 540, y: 240)],
            ink: marker, width: 26))

        return PKDrawing(strokes: strokes).dataRepresentation()
    }

    /// A small geometric doodle (a box with a diagonal).
    static func doodle(color: UIColor) -> Data {
        let fountain = PKInk(.fountainPen, color: color)
        var strokes: [PKStroke] = []
        let box: [CGPoint] = [
            CGPoint(x: 200, y: 220), CGPoint(x: 600, y: 220),
            CGPoint(x: 600, y: 560), CGPoint(x: 200, y: 560),
            CGPoint(x: 200, y: 220)
        ]
        strokes.append(stroke(points: box, ink: fountain, width: 6))
        strokes.append(stroke(
            points: [CGPoint(x: 200, y: 220), CGPoint(x: 600, y: 560)],
            ink: fountain, width: 6))
        return PKDrawing(strokes: strokes).dataRepresentation()
    }
}

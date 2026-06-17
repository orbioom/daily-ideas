import CoreGraphics

// Six basic shapes.
extension GlyphLibrary {

    static let shapes: [Glyph] = [
        Glyph(key: "S_circle", set: .shapes, display: "●", label: "Circle", strokes: [
            GlyphStroke(points: [p(0.50, 0.12), p(0.28, 0.24), p(0.18, 0.50), p(0.28, 0.76), p(0.50, 0.88), p(0.72, 0.76), p(0.82, 0.50), p(0.72, 0.24), p(0.50, 0.12)], start: .top)
        ]),
        Glyph(key: "S_square", set: .shapes, display: "■", label: "Square", strokes: [
            GlyphStroke(points: [p(0.20, 0.20), p(0.80, 0.20), p(0.80, 0.80), p(0.20, 0.80), p(0.20, 0.20)], start: .topLeft)
        ]),
        Glyph(key: "S_triangle", set: .shapes, display: "▲", label: "Triangle", strokes: [
            GlyphStroke(points: [p(0.50, 0.16), p(0.84, 0.84), p(0.16, 0.84), p(0.50, 0.16)], start: .top)
        ]),
        Glyph(key: "S_rectangle", set: .shapes, display: "▬", label: "Rectangle", strokes: [
            GlyphStroke(points: [p(0.14, 0.30), p(0.86, 0.30), p(0.86, 0.70), p(0.14, 0.70), p(0.14, 0.30)], start: .topLeft)
        ]),
        Glyph(key: "S_diamond", set: .shapes, display: "◆", label: "Diamond", strokes: [
            GlyphStroke(points: [p(0.50, 0.12), p(0.84, 0.50), p(0.50, 0.88), p(0.16, 0.50), p(0.50, 0.12)], start: .top)
        ]),
        Glyph(key: "S_star", set: .shapes, display: "★", label: "Star", strokes: [
            GlyphStroke(points: [p(0.50, 0.10), p(0.61, 0.40), p(0.90, 0.40), p(0.66, 0.60), p(0.76, 0.90), p(0.50, 0.70), p(0.24, 0.90), p(0.34, 0.60), p(0.10, 0.40), p(0.39, 0.40), p(0.50, 0.10)], start: .top)
        ]),
        Glyph(key: "S_heart", set: .shapes, display: "♥", label: "Heart", strokes: [
            GlyphStroke(points: [p(0.50, 0.32), p(0.40, 0.18), p(0.24, 0.18), p(0.14, 0.32), p(0.16, 0.50), p(0.50, 0.86), p(0.84, 0.50), p(0.86, 0.32), p(0.76, 0.18), p(0.60, 0.18), p(0.50, 0.32)], start: .center)
        ])
    ]
}

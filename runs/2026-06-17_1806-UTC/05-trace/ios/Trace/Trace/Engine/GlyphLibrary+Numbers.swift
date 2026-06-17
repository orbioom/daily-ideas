import CoreGraphics

// Simplified number forms 0–9.
extension GlyphLibrary {

    static let numbers: [Glyph] = [
        Glyph(key: "N_0", set: .numbers, display: "0", label: "Number zero", strokes: [
            GlyphStroke(points: [p(0.50, 0.10), p(0.30, 0.22), p(0.24, 0.50), p(0.30, 0.78), p(0.50, 0.90), p(0.70, 0.78), p(0.76, 0.50), p(0.70, 0.22), p(0.50, 0.10)], start: .top)
        ]),
        Glyph(key: "N_1", set: .numbers, display: "1", label: "Number one", strokes: [
            GlyphStroke(points: [p(0.34, 0.26), p(0.52, 0.10), p(0.52, 0.90)], start: .topLeft),
            GlyphStroke(points: [p(0.34, 0.90), p(0.70, 0.90)], start: .bottom)
        ]),
        Glyph(key: "N_2", set: .numbers, display: "2", label: "Number two", strokes: [
            GlyphStroke(points: [p(0.28, 0.28), p(0.42, 0.12), p(0.62, 0.14), p(0.72, 0.32), p(0.62, 0.50), p(0.30, 0.78), p(0.26, 0.90), p(0.74, 0.90)], start: .top)
        ]),
        Glyph(key: "N_3", set: .numbers, display: "3", label: "Number three", strokes: [
            GlyphStroke(points: [p(0.28, 0.20), p(0.46, 0.10), p(0.66, 0.16), p(0.70, 0.32), p(0.56, 0.46), p(0.42, 0.50)], start: .top),
            GlyphStroke(points: [p(0.46, 0.50), p(0.66, 0.56), p(0.74, 0.72), p(0.62, 0.88), p(0.42, 0.90), p(0.26, 0.80)], start: .center)
        ]),
        Glyph(key: "N_4", set: .numbers, display: "4", label: "Number four", strokes: [
            GlyphStroke(points: [p(0.60, 0.10), p(0.26, 0.62), p(0.74, 0.62)], start: .top),
            GlyphStroke(points: [p(0.60, 0.10), p(0.60, 0.90)], start: .top)
        ]),
        Glyph(key: "N_5", set: .numbers, display: "5", label: "Number five", strokes: [
            GlyphStroke(points: [p(0.66, 0.12), p(0.34, 0.12), p(0.32, 0.44), p(0.50, 0.40), p(0.68, 0.50), p(0.72, 0.70), p(0.58, 0.88), p(0.36, 0.88), p(0.26, 0.78)], start: .topRight)
        ]),
        Glyph(key: "N_6", set: .numbers, display: "6", label: "Number six", strokes: [
            GlyphStroke(points: [p(0.66, 0.16), p(0.46, 0.12), p(0.32, 0.30), p(0.28, 0.58), p(0.32, 0.80), p(0.50, 0.90), p(0.68, 0.82), p(0.72, 0.64), p(0.58, 0.52), p(0.38, 0.54), p(0.28, 0.64)], start: .topRight)
        ]),
        Glyph(key: "N_7", set: .numbers, display: "7", label: "Number seven", strokes: [
            GlyphStroke(points: [p(0.26, 0.12), p(0.74, 0.12), p(0.44, 0.90)], start: .top)
        ]),
        Glyph(key: "N_8", set: .numbers, display: "8", label: "Number eight", strokes: [
            GlyphStroke(points: [p(0.50, 0.50), p(0.36, 0.40), p(0.36, 0.22), p(0.50, 0.12), p(0.64, 0.22), p(0.64, 0.40), p(0.50, 0.50), p(0.34, 0.62), p(0.30, 0.78), p(0.42, 0.90), p(0.58, 0.90), p(0.70, 0.78), p(0.66, 0.62), p(0.50, 0.50)], start: .center)
        ]),
        Glyph(key: "N_9", set: .numbers, display: "9", label: "Number nine", strokes: [
            GlyphStroke(points: [p(0.70, 0.42), p(0.56, 0.50), p(0.40, 0.46), p(0.32, 0.32), p(0.40, 0.18), p(0.58, 0.12), p(0.70, 0.24), p(0.72, 0.50), p(0.66, 0.78), p(0.48, 0.90)], start: .top)
        ])
    ]
}

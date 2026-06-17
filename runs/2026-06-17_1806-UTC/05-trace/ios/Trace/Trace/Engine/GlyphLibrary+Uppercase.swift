import CoreGraphics

// Simplified straight-segment uppercase letterforms in a 0...1 unit square.
// Strokes are ordered the way a child should draw them; directionality is the
// priority, not typographic beauty. Curves are approximated with polylines.
extension GlyphLibrary {

    static let uppercase: [Glyph] = [
        Glyph(key: "U_A", set: .uppercase, display: "A", label: "Capital A", strokes: [
            GlyphStroke(points: [p(0.50, 0.10), p(0.20, 0.90)], start: .top),
            GlyphStroke(points: [p(0.50, 0.10), p(0.80, 0.90)], start: .top),
            GlyphStroke(points: [p(0.32, 0.58), p(0.68, 0.58)], start: .left)
        ]),
        Glyph(key: "U_B", set: .uppercase, display: "B", label: "Capital B", strokes: [
            GlyphStroke(points: [p(0.28, 0.10), p(0.28, 0.90)], start: .top),
            GlyphStroke(points: [p(0.28, 0.10), p(0.62, 0.16), p(0.70, 0.30), p(0.62, 0.44), p(0.28, 0.50)], start: .topLeft),
            GlyphStroke(points: [p(0.28, 0.50), p(0.66, 0.56), p(0.76, 0.70), p(0.66, 0.84), p(0.28, 0.90)], start: .left)
        ]),
        Glyph(key: "U_C", set: .uppercase, display: "C", label: "Capital C", strokes: [
            GlyphStroke(points: [p(0.74, 0.24), p(0.56, 0.12), p(0.34, 0.16), p(0.22, 0.40), p(0.22, 0.60), p(0.34, 0.84), p(0.56, 0.88), p(0.74, 0.76)], start: .topRight)
        ]),
        Glyph(key: "U_D", set: .uppercase, display: "D", label: "Capital D", strokes: [
            GlyphStroke(points: [p(0.28, 0.10), p(0.28, 0.90)], start: .top),
            GlyphStroke(points: [p(0.28, 0.10), p(0.58, 0.16), p(0.74, 0.40), p(0.74, 0.60), p(0.58, 0.84), p(0.28, 0.90)], start: .topLeft)
        ]),
        Glyph(key: "U_E", set: .uppercase, display: "E", label: "Capital E", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.30, 0.90)], start: .top),
            GlyphStroke(points: [p(0.30, 0.10), p(0.72, 0.10)], start: .topLeft),
            GlyphStroke(points: [p(0.30, 0.50), p(0.64, 0.50)], start: .left),
            GlyphStroke(points: [p(0.30, 0.90), p(0.72, 0.90)], start: .bottomLeft)
        ]),
        Glyph(key: "U_F", set: .uppercase, display: "F", label: "Capital F", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.30, 0.90)], start: .top),
            GlyphStroke(points: [p(0.30, 0.10), p(0.72, 0.10)], start: .topLeft),
            GlyphStroke(points: [p(0.30, 0.50), p(0.64, 0.50)], start: .left)
        ]),
        Glyph(key: "U_G", set: .uppercase, display: "G", label: "Capital G", strokes: [
            GlyphStroke(points: [p(0.74, 0.24), p(0.56, 0.12), p(0.34, 0.16), p(0.22, 0.40), p(0.22, 0.60), p(0.34, 0.84), p(0.58, 0.88), p(0.74, 0.74), p(0.74, 0.56), p(0.54, 0.56)], start: .topRight)
        ]),
        Glyph(key: "U_H", set: .uppercase, display: "H", label: "Capital H", strokes: [
            GlyphStroke(points: [p(0.28, 0.10), p(0.28, 0.90)], start: .top),
            GlyphStroke(points: [p(0.72, 0.10), p(0.72, 0.90)], start: .top),
            GlyphStroke(points: [p(0.28, 0.50), p(0.72, 0.50)], start: .left)
        ]),
        Glyph(key: "U_I", set: .uppercase, display: "I", label: "Capital I", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.70, 0.10)], start: .top),
            GlyphStroke(points: [p(0.50, 0.10), p(0.50, 0.90)], start: .top),
            GlyphStroke(points: [p(0.30, 0.90), p(0.70, 0.90)], start: .bottom)
        ]),
        Glyph(key: "U_J", set: .uppercase, display: "J", label: "Capital J", strokes: [
            GlyphStroke(points: [p(0.66, 0.10), p(0.66, 0.66), p(0.58, 0.84), p(0.40, 0.88), p(0.26, 0.74), p(0.26, 0.64)], start: .top)
        ]),
        Glyph(key: "U_K", set: .uppercase, display: "K", label: "Capital K", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.30, 0.90)], start: .top),
            GlyphStroke(points: [p(0.72, 0.10), p(0.30, 0.50)], start: .topRight),
            GlyphStroke(points: [p(0.30, 0.50), p(0.74, 0.90)], start: .left)
        ]),
        Glyph(key: "U_L", set: .uppercase, display: "L", label: "Capital L", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.30, 0.90), p(0.72, 0.90)], start: .top)
        ]),
        Glyph(key: "U_M", set: .uppercase, display: "M", label: "Capital M", strokes: [
            GlyphStroke(points: [p(0.22, 0.90), p(0.22, 0.10), p(0.50, 0.60), p(0.78, 0.10), p(0.78, 0.90)], start: .bottomLeft)
        ]),
        Glyph(key: "U_N", set: .uppercase, display: "N", label: "Capital N", strokes: [
            GlyphStroke(points: [p(0.26, 0.90), p(0.26, 0.10), p(0.74, 0.90), p(0.74, 0.10)], start: .bottomLeft)
        ]),
        Glyph(key: "U_O", set: .uppercase, display: "O", label: "Capital O", strokes: [
            GlyphStroke(points: [p(0.50, 0.10), p(0.28, 0.22), p(0.20, 0.50), p(0.28, 0.78), p(0.50, 0.90), p(0.72, 0.78), p(0.80, 0.50), p(0.72, 0.22), p(0.50, 0.10)], start: .top)
        ]),
        Glyph(key: "U_P", set: .uppercase, display: "P", label: "Capital P", strokes: [
            GlyphStroke(points: [p(0.30, 0.90), p(0.30, 0.10)], start: .bottom),
            GlyphStroke(points: [p(0.30, 0.10), p(0.64, 0.16), p(0.74, 0.32), p(0.64, 0.48), p(0.30, 0.54)], start: .topLeft)
        ]),
        Glyph(key: "U_Q", set: .uppercase, display: "Q", label: "Capital Q", strokes: [
            GlyphStroke(points: [p(0.50, 0.10), p(0.28, 0.22), p(0.20, 0.50), p(0.28, 0.78), p(0.50, 0.90), p(0.72, 0.78), p(0.80, 0.50), p(0.72, 0.22), p(0.50, 0.10)], start: .top),
            GlyphStroke(points: [p(0.60, 0.70), p(0.82, 0.92)], start: .center)
        ]),
        Glyph(key: "U_R", set: .uppercase, display: "R", label: "Capital R", strokes: [
            GlyphStroke(points: [p(0.30, 0.90), p(0.30, 0.10)], start: .bottom),
            GlyphStroke(points: [p(0.30, 0.10), p(0.64, 0.16), p(0.74, 0.32), p(0.64, 0.48), p(0.30, 0.54)], start: .topLeft),
            GlyphStroke(points: [p(0.44, 0.54), p(0.74, 0.90)], start: .center)
        ]),
        Glyph(key: "U_S", set: .uppercase, display: "S", label: "Capital S", strokes: [
            GlyphStroke(points: [p(0.74, 0.24), p(0.56, 0.12), p(0.34, 0.16), p(0.28, 0.34), p(0.42, 0.46), p(0.62, 0.54), p(0.74, 0.68), p(0.66, 0.84), p(0.44, 0.88), p(0.26, 0.76)], start: .topRight)
        ]),
        Glyph(key: "U_T", set: .uppercase, display: "T", label: "Capital T", strokes: [
            GlyphStroke(points: [p(0.20, 0.10), p(0.80, 0.10)], start: .top),
            GlyphStroke(points: [p(0.50, 0.10), p(0.50, 0.90)], start: .top)
        ]),
        Glyph(key: "U_U", set: .uppercase, display: "U", label: "Capital U", strokes: [
            GlyphStroke(points: [p(0.26, 0.10), p(0.26, 0.62), p(0.38, 0.84), p(0.50, 0.88), p(0.62, 0.84), p(0.74, 0.62), p(0.74, 0.10)], start: .top)
        ]),
        Glyph(key: "U_V", set: .uppercase, display: "V", label: "Capital V", strokes: [
            GlyphStroke(points: [p(0.24, 0.10), p(0.50, 0.90), p(0.76, 0.10)], start: .top)
        ]),
        Glyph(key: "U_W", set: .uppercase, display: "W", label: "Capital W", strokes: [
            GlyphStroke(points: [p(0.16, 0.10), p(0.34, 0.90), p(0.50, 0.40), p(0.66, 0.90), p(0.84, 0.10)], start: .top)
        ]),
        Glyph(key: "U_X", set: .uppercase, display: "X", label: "Capital X", strokes: [
            GlyphStroke(points: [p(0.24, 0.10), p(0.76, 0.90)], start: .topLeft),
            GlyphStroke(points: [p(0.76, 0.10), p(0.24, 0.90)], start: .topRight)
        ]),
        Glyph(key: "U_Y", set: .uppercase, display: "Y", label: "Capital Y", strokes: [
            GlyphStroke(points: [p(0.24, 0.10), p(0.50, 0.50)], start: .topLeft),
            GlyphStroke(points: [p(0.76, 0.10), p(0.50, 0.50), p(0.50, 0.90)], start: .topRight)
        ]),
        Glyph(key: "U_Z", set: .uppercase, display: "Z", label: "Capital Z", strokes: [
            GlyphStroke(points: [p(0.24, 0.10), p(0.76, 0.10), p(0.24, 0.90), p(0.76, 0.90)], start: .top)
        ])
    ]
}

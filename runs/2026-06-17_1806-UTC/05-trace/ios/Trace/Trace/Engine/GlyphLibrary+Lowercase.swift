import CoreGraphics

// Simplified lowercase letterforms. Ascenders/descenders use the full height;
// x-height letters sit roughly in the lower-middle band (~0.40 to 0.90).
extension GlyphLibrary {

    static let lowercase: [Glyph] = [
        Glyph(key: "L_a", set: .lowercase, display: "a", label: "Lowercase a", strokes: [
            GlyphStroke(points: [p(0.70, 0.46), p(0.50, 0.40), p(0.34, 0.50), p(0.30, 0.66), p(0.38, 0.84), p(0.56, 0.88), p(0.70, 0.78)], start: .topRight),
            GlyphStroke(points: [p(0.70, 0.42), p(0.70, 0.90)], start: .top)
        ]),
        Glyph(key: "L_b", set: .lowercase, display: "b", label: "Lowercase b", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.30, 0.90)], start: .top),
            GlyphStroke(points: [p(0.30, 0.56), p(0.48, 0.44), p(0.66, 0.50), p(0.72, 0.66), p(0.66, 0.82), p(0.48, 0.90), p(0.30, 0.84)], start: .left)
        ]),
        Glyph(key: "L_c", set: .lowercase, display: "c", label: "Lowercase c", strokes: [
            GlyphStroke(points: [p(0.70, 0.52), p(0.52, 0.42), p(0.36, 0.50), p(0.30, 0.66), p(0.36, 0.82), p(0.52, 0.90), p(0.70, 0.80)], start: .topRight)
        ]),
        Glyph(key: "L_d", set: .lowercase, display: "d", label: "Lowercase d", strokes: [
            GlyphStroke(points: [p(0.70, 0.10), p(0.70, 0.90)], start: .top),
            GlyphStroke(points: [p(0.70, 0.56), p(0.52, 0.44), p(0.34, 0.50), p(0.28, 0.66), p(0.34, 0.82), p(0.52, 0.90), p(0.70, 0.84)], start: .right)
        ]),
        Glyph(key: "L_e", set: .lowercase, display: "e", label: "Lowercase e", strokes: [
            GlyphStroke(points: [p(0.30, 0.66), p(0.70, 0.66), p(0.68, 0.50), p(0.50, 0.42), p(0.34, 0.50), p(0.30, 0.66), p(0.36, 0.82), p(0.54, 0.90), p(0.70, 0.80)], start: .left)
        ]),
        Glyph(key: "L_f", set: .lowercase, display: "f", label: "Lowercase f", strokes: [
            GlyphStroke(points: [p(0.62, 0.16), p(0.46, 0.18), p(0.40, 0.34), p(0.40, 0.90)], start: .topRight),
            GlyphStroke(points: [p(0.24, 0.44), p(0.62, 0.44)], start: .left)
        ]),
        Glyph(key: "L_g", set: .lowercase, display: "g", label: "Lowercase g", strokes: [
            GlyphStroke(points: [p(0.68, 0.50), p(0.50, 0.42), p(0.34, 0.50), p(0.30, 0.64), p(0.38, 0.78), p(0.54, 0.82), p(0.68, 0.72)], start: .topRight),
            GlyphStroke(points: [p(0.68, 0.44), p(0.68, 0.86), p(0.58, 0.98), p(0.40, 0.98), p(0.30, 0.88)], start: .top)
        ]),
        Glyph(key: "L_h", set: .lowercase, display: "h", label: "Lowercase h", strokes: [
            GlyphStroke(points: [p(0.30, 0.10), p(0.30, 0.90)], start: .top),
            GlyphStroke(points: [p(0.30, 0.56), p(0.46, 0.44), p(0.64, 0.48), p(0.70, 0.64), p(0.70, 0.90)], start: .left)
        ]),
        Glyph(key: "L_i", set: .lowercase, display: "i", label: "Lowercase i", strokes: [
            GlyphStroke(points: [p(0.50, 0.44), p(0.50, 0.90)], start: .top),
            GlyphStroke(points: [p(0.50, 0.22), p(0.50, 0.28)], start: .top)
        ]),
        Glyph(key: "L_j", set: .lowercase, display: "j", label: "Lowercase j", strokes: [
            GlyphStroke(points: [p(0.58, 0.44), p(0.58, 0.84), p(0.50, 0.96), p(0.36, 0.96), p(0.28, 0.86)], start: .top),
            GlyphStroke(points: [p(0.58, 0.22), p(0.58, 0.28)], start: .top)
        ]),
        Glyph(key: "L_k", set: .lowercase, display: "k", label: "Lowercase k", strokes: [
            GlyphStroke(points: [p(0.32, 0.10), p(0.32, 0.90)], start: .top),
            GlyphStroke(points: [p(0.68, 0.46), p(0.32, 0.68)], start: .right),
            GlyphStroke(points: [p(0.32, 0.68), p(0.70, 0.90)], start: .center)
        ]),
        Glyph(key: "L_l", set: .lowercase, display: "l", label: "Lowercase l", strokes: [
            GlyphStroke(points: [p(0.48, 0.10), p(0.48, 0.78), p(0.56, 0.90)], start: .top)
        ]),
        Glyph(key: "L_m", set: .lowercase, display: "m", label: "Lowercase m", strokes: [
            GlyphStroke(points: [p(0.22, 0.44), p(0.22, 0.90)], start: .top),
            GlyphStroke(points: [p(0.22, 0.54), p(0.36, 0.44), p(0.48, 0.50), p(0.50, 0.64), p(0.50, 0.90)], start: .left),
            GlyphStroke(points: [p(0.50, 0.54), p(0.64, 0.44), p(0.76, 0.50), p(0.78, 0.64), p(0.78, 0.90)], start: .center)
        ]),
        Glyph(key: "L_n", set: .lowercase, display: "n", label: "Lowercase n", strokes: [
            GlyphStroke(points: [p(0.30, 0.44), p(0.30, 0.90)], start: .top),
            GlyphStroke(points: [p(0.30, 0.54), p(0.46, 0.44), p(0.64, 0.50), p(0.70, 0.64), p(0.70, 0.90)], start: .left)
        ]),
        Glyph(key: "L_o", set: .lowercase, display: "o", label: "Lowercase o", strokes: [
            GlyphStroke(points: [p(0.50, 0.42), p(0.34, 0.50), p(0.28, 0.66), p(0.34, 0.82), p(0.50, 0.90), p(0.66, 0.82), p(0.72, 0.66), p(0.66, 0.50), p(0.50, 0.42)], start: .top)
        ]),
        Glyph(key: "L_p", set: .lowercase, display: "p", label: "Lowercase p", strokes: [
            GlyphStroke(points: [p(0.30, 0.42), p(0.30, 0.98)], start: .top),
            GlyphStroke(points: [p(0.30, 0.54), p(0.48, 0.44), p(0.66, 0.50), p(0.72, 0.64), p(0.66, 0.78), p(0.48, 0.86), p(0.30, 0.80)], start: .left)
        ]),
        Glyph(key: "L_q", set: .lowercase, display: "q", label: "Lowercase q", strokes: [
            GlyphStroke(points: [p(0.70, 0.42), p(0.70, 0.98)], start: .top),
            GlyphStroke(points: [p(0.70, 0.54), p(0.52, 0.44), p(0.34, 0.50), p(0.28, 0.64), p(0.34, 0.78), p(0.52, 0.86), p(0.70, 0.80)], start: .right)
        ]),
        Glyph(key: "L_r", set: .lowercase, display: "r", label: "Lowercase r", strokes: [
            GlyphStroke(points: [p(0.34, 0.44), p(0.34, 0.90)], start: .top),
            GlyphStroke(points: [p(0.34, 0.54), p(0.48, 0.44), p(0.64, 0.44), p(0.72, 0.50)], start: .left)
        ]),
        Glyph(key: "L_s", set: .lowercase, display: "s", label: "Lowercase s", strokes: [
            GlyphStroke(points: [p(0.68, 0.50), p(0.52, 0.42), p(0.36, 0.46), p(0.34, 0.58), p(0.48, 0.66), p(0.64, 0.72), p(0.66, 0.82), p(0.50, 0.90), p(0.32, 0.84)], start: .topRight)
        ]),
        Glyph(key: "L_t", set: .lowercase, display: "t", label: "Lowercase t", strokes: [
            GlyphStroke(points: [p(0.46, 0.18), p(0.46, 0.78), p(0.56, 0.90), p(0.66, 0.84)], start: .top),
            GlyphStroke(points: [p(0.28, 0.44), p(0.64, 0.44)], start: .left)
        ]),
        Glyph(key: "L_u", set: .lowercase, display: "u", label: "Lowercase u", strokes: [
            GlyphStroke(points: [p(0.30, 0.44), p(0.30, 0.74), p(0.40, 0.88), p(0.56, 0.88), p(0.68, 0.76)], start: .top),
            GlyphStroke(points: [p(0.68, 0.44), p(0.68, 0.90)], start: .top)
        ]),
        Glyph(key: "L_v", set: .lowercase, display: "v", label: "Lowercase v", strokes: [
            GlyphStroke(points: [p(0.30, 0.44), p(0.50, 0.90), p(0.70, 0.44)], start: .top)
        ]),
        Glyph(key: "L_w", set: .lowercase, display: "w", label: "Lowercase w", strokes: [
            GlyphStroke(points: [p(0.20, 0.44), p(0.34, 0.90), p(0.50, 0.58), p(0.66, 0.90), p(0.80, 0.44)], start: .top)
        ]),
        Glyph(key: "L_x", set: .lowercase, display: "x", label: "Lowercase x", strokes: [
            GlyphStroke(points: [p(0.30, 0.44), p(0.70, 0.90)], start: .topLeft),
            GlyphStroke(points: [p(0.70, 0.44), p(0.30, 0.90)], start: .topRight)
        ]),
        Glyph(key: "L_y", set: .lowercase, display: "y", label: "Lowercase y", strokes: [
            GlyphStroke(points: [p(0.30, 0.44), p(0.50, 0.82)], start: .top),
            GlyphStroke(points: [p(0.70, 0.44), p(0.50, 0.82), p(0.40, 0.98), p(0.26, 0.98)], start: .top)
        ]),
        Glyph(key: "L_z", set: .lowercase, display: "z", label: "Lowercase z", strokes: [
            GlyphStroke(points: [p(0.30, 0.44), p(0.70, 0.44), p(0.30, 0.90), p(0.70, 0.90)], start: .top)
        ])
    ]
}

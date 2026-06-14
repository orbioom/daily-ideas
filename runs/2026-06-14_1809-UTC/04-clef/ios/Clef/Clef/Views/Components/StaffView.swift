import SwiftUI

/// Draws a single note on a 5-line staff for the given clef using Canvas.
/// Renders staff lines, a clef glyph, ledger lines, and an elegant note head + stem.
struct StaffView: View {
    let clef: Clef
    let midi: Int
    /// Optional tint for the note head (e.g. green/red feedback).
    var noteColor: Color = Theme.staff
    /// Accessibility description of the note (e.g. "Note E, bottom line").
    var accessibilityText: String

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let staffLines = 5
        // Reserve horizontal room for the clef glyph on the left.
        let leftPad: CGFloat = size.width * 0.18
        let rightPad: CGFloat = size.width * 0.10
        let usableWidth = max(10, size.width - leftPad - rightPad)

        // Line gap chosen to keep the staff vertically centered with room for ledgers.
        let lineGap = min(size.height / 12, 18)
        let staffHeight = lineGap * CGFloat(staffLines - 1)
        let centerY = size.height / 2
        let topLineY = centerY - staffHeight / 2
        let bottomLineY = topLineY + staffHeight

        let lineColor = Theme.staff
        let lineWidth: CGFloat = 1.4

        // Staff lines.
        for i in 0..<staffLines {
            let y = topLineY + CGFloat(i) * lineGap
            var path = Path()
            path.move(to: CGPoint(x: leftPad, y: y))
            path.addLine(to: CGPoint(x: leftPad + usableWidth, y: y))
            context.stroke(path, with: .color(lineColor.opacity(0.85)), lineWidth: lineWidth)
        }

        // Clef glyph (drawn as text — robust across SDKs).
        drawClefGlyph(in: &context, leftPad: leftPad, topLineY: topLineY,
                      bottomLineY: bottomLineY, lineGap: lineGap, lineColor: lineColor)

        // Note placement.
        let noteX = leftPad + usableWidth * 0.62
        let bottom = clef.bottomLineMIDI
        let step = StaffLayout.diatonicStep(midi: midi, bottomLineMIDI: bottom)
        let offset = StaffLayout.verticalOffset(diatonicStep: step, lineGap: lineGap)
        let noteY = bottomLineY - offset
        let headRadiusX = lineGap * 0.72
        let headRadiusY = lineGap * 0.56

        // Ledger lines.
        let ledgerHalfWidth = headRadiusX * 1.6
        for ledgerStep in StaffLayout.ledgerSteps(diatonicStep: step) {
            let ly = bottomLineY - StaffLayout.verticalOffset(diatonicStep: ledgerStep, lineGap: lineGap)
            var lp = Path()
            lp.move(to: CGPoint(x: noteX - ledgerHalfWidth, y: ly))
            lp.addLine(to: CGPoint(x: noteX + ledgerHalfWidth, y: ly))
            context.stroke(lp, with: .color(lineColor.opacity(0.85)), lineWidth: lineWidth)
        }

        // Accidental sign for sharp/flat notes (drawn left of the head).
        let pitch = Pitch(midi)
        if !pitch.isNatural {
            let symbol = pitch.name(useFlats: false).contains("♯") ? "♯" : "♭"
            let accText = Text(symbol)
                .font(.system(size: lineGap * 2.0, weight: .semibold, design: .serif))
                .foregroundColor(noteColor)
            context.draw(accText, at: CGPoint(x: noteX - headRadiusX - lineGap * 0.9, y: noteY))
        }

        // Note head: a filled, slightly rotated ellipse.
        let headRect = CGRect(x: noteX - headRadiusX, y: noteY - headRadiusY,
                              width: headRadiusX * 2, height: headRadiusY * 2)
        var headContext = context
        headContext.translateBy(x: noteX, y: noteY)
        headContext.rotate(by: .degrees(-18))
        headContext.translateBy(x: -noteX, y: -noteY)
        headContext.fill(Path(ellipseIn: headRect), with: .color(noteColor))

        // Stem: up if note is low on the staff, down if high (classical convention,
        // here simplified — stem up on the right unless the note is high).
        let stemHeight = lineGap * 3.2
        let stemUp = step <= 4
        var stem = Path()
        if stemUp {
            let sx = noteX + headRadiusX * 0.88
            stem.move(to: CGPoint(x: sx, y: noteY))
            stem.addLine(to: CGPoint(x: sx, y: noteY - stemHeight))
        } else {
            let sx = noteX - headRadiusX * 0.88
            stem.move(to: CGPoint(x: sx, y: noteY))
            stem.addLine(to: CGPoint(x: sx, y: noteY + stemHeight))
        }
        context.stroke(stem, with: .color(noteColor), lineWidth: 2.0)
    }

    /// Draw a stylized clef indicator. Uses the conventional letter the clef is named
    /// for (G/F/C) in serif, plus a small label so it reads clearly in both modes.
    private func drawClefGlyph(in context: inout GraphicsContext,
                               leftPad: CGFloat,
                               topLineY: CGFloat,
                               bottomLineY: CGFloat,
                               lineGap: CGFloat,
                               lineColor: Color) {
        let glyph: String
        switch clef {
        case .treble, .grand: glyph = "𝄞"
        case .bass: glyph = "𝄢"
        case .alto: glyph = "𝄡"
        }
        let centerY = (topLineY + bottomLineY) / 2
        let text = Text(glyph)
            .font(.system(size: lineGap * 5.5, design: .serif))
            .foregroundColor(lineColor)
        context.draw(text, at: CGPoint(x: leftPad * 0.5, y: centerY))
    }
}

import SwiftUI

/// Draws a standard chord box: strings as vertical lines (low string on the
/// left), frets as horizontal lines, finger dots, and ×/○ markers on top.
struct ChordDiagram: View {
    let chord: Chord
    var showFingers: Bool = true
    /// Cells (frets) drawn in the window.
    private let windowFrets = 5

    var body: some View {
        Canvas { ctx, size in draw(in: ctx, size: size) }
            .aspectRatio(0.82, contentMode: .fit)
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts: [String] = ["\(chord.symbol) chord"]
        for (i, f) in chord.frets.enumerated() {
            let s = "string \(i + 1)"
            switch f {
            case -1: parts.append("\(s) muted")
            case 0:  parts.append("\(s) open")
            default: parts.append("\(s) fret \(f)")
            }
        }
        return parts.joined(separator: ", ")
    }

    private func draw(in ctx: GraphicsContext, size: CGSize) {
        let n = max(2, chord.frets.count)
        let markerH = size.height * 0.12
        let labelW: CGFloat = chord.baseFret > 1 ? size.width * 0.12 : 0
        let pad: CGFloat = size.width * 0.07
        let boardLeft = pad + labelW
        let boardRight = size.width - pad
        let boardTop = markerH + size.height * 0.04
        let boardBottom = size.height - size.height * 0.02
        let boardW = boardRight - boardLeft
        let boardH = boardBottom - boardTop
        guard boardW > 0, boardH > 0 else { return }

        let stringGap = boardW / CGFloat(n - 1)
        let fretGap = boardH / CGFloat(windowFrets)
        let leftHanded = UserDefaults.standard.bool(forKey: "leftHanded")
        // String 0 (lowest) sits on the left for right-handed players, mirrored
        // to the right for left-handed players.
        func stringX(_ j: Int) -> CGFloat {
            leftHanded ? boardRight - CGFloat(j) * stringGap
                       : boardLeft + CGFloat(j) * stringGap
        }

        let line = Color.dyn(0xCBB48F, 0xB79A6E)
        let lineColor = GraphicsContext.Shading.color(line)
        let boardFill = GraphicsContext.Shading.color(Color.dyn(0x3A2A1C, 0x2A1E12))
        let dotColor = GraphicsContext.Shading.color(Color(hex: 0xB5731F))
        let mutedColor = GraphicsContext.Shading.color(Color.dyn(0x9A8870, 0x7E6E5C))
        let openColor = GraphicsContext.Shading.color(Color.dyn(0x6E5E4C, 0xC3B09A))

        // Board background
        let boardRect = CGRect(x: boardLeft, y: boardTop, width: boardW, height: boardH)
        ctx.fill(Path(roundedRect: boardRect, cornerRadius: 4), with: boardFill)

        // Frets
        let nutThick = chord.baseFret == 1
        for i in 0...windowFrets {
            let y = boardTop + CGFloat(i) * fretGap
            var p = Path()
            p.move(to: CGPoint(x: boardLeft, y: y))
            p.addLine(to: CGPoint(x: boardRight, y: y))
            let w: CGFloat = (i == 0 && nutThick) ? 6 : 1.5
            ctx.stroke(p, with: lineColor, lineWidth: w)
        }
        // Strings
        for j in 0..<n {
            var p = Path()
            p.move(to: CGPoint(x: stringX(j), y: boardTop))
            p.addLine(to: CGPoint(x: stringX(j), y: boardBottom))
            ctx.stroke(p, with: lineColor, lineWidth: 1.5)
        }

        // Base-fret label for moved shapes
        if chord.baseFret > 1 {
            let t = Text("\(chord.baseFret)fr")
                .font(.system(size: max(9, fretGap * 0.32), weight: .semibold, design: .rounded))
                .foregroundStyle(Color.dyn(0x6E5E4C, 0xC3B09A))
            ctx.draw(t, at: CGPoint(x: boardLeft - labelW * 0.5,
                                    y: boardTop + fretGap * 0.5), anchor: .center)
        }

        // Top markers: × (muted) / ○ (open)
        let mr = min(stringGap, markerH) * 0.28
        for (j, f) in chord.frets.enumerated() {
            let cx = stringX(j), cy = boardTop - markerH * 0.55
            if f == -1 {
                var p = Path()
                p.move(to: CGPoint(x: cx - mr, y: cy - mr)); p.addLine(to: CGPoint(x: cx + mr, y: cy + mr))
                p.move(to: CGPoint(x: cx + mr, y: cy - mr)); p.addLine(to: CGPoint(x: cx - mr, y: cy + mr))
                ctx.stroke(p, with: mutedColor, lineWidth: 2)
            } else if f == 0 {
                let r = CGRect(x: cx - mr, y: cy - mr, width: mr * 2, height: mr * 2)
                ctx.stroke(Path(ellipseIn: r), with: openColor, lineWidth: 2)
            }
        }

        // Barre bar (a finger covering ≥2 strings at one fret)
        var groups: [String: [Int]] = [:]
        for (j, f) in chord.frets.enumerated() where f > 0 && chord.fingers.indices.contains(j) {
            let fg = chord.fingers[j]
            if fg > 0 { groups["\(fg)-\(f)", default: []].append(j) }
        }
        let dotR = min(stringGap, fretGap) * 0.34
        for (key, strings) in groups where strings.count >= 2 {
            guard let fret = Int(key.split(separator: "-").last ?? "") else { continue }
            let rel = fret - chord.baseFret
            guard rel >= 0, rel < windowFrets else { continue }
            let y = boardTop + (CGFloat(rel) + 0.5) * fretGap
            let xa = stringX(strings.min() ?? 0)
            let xb = stringX(strings.max() ?? 0)
            let x0 = min(xa, xb), x1 = max(xa, xb)
            let bar = CGRect(x: x0 - dotR, y: y - dotR, width: (x1 - x0) + dotR * 2, height: dotR * 2)
            ctx.fill(Path(roundedRect: bar, cornerRadius: dotR), with: dotColor)
        }

        // Finger dots
        for (j, f) in chord.frets.enumerated() where f > 0 {
            let rel = f - chord.baseFret
            guard rel >= 0, rel < windowFrets else { continue }
            let x = stringX(j)
            let y = boardTop + (CGFloat(rel) + 0.5) * fretGap
            let r = CGRect(x: x - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2)
            ctx.fill(Path(ellipseIn: r), with: dotColor)
            if showFingers, chord.fingers.indices.contains(j), chord.fingers[j] > 0 {
                let t = Text("\(chord.fingers[j])")
                    .font(.system(size: dotR * 1.2, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                ctx.draw(t, at: CGPoint(x: x, y: y), anchor: .center)
            }
        }
    }
}

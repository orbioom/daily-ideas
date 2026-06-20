import SwiftUI

// MARK: - Artwork Renderer (one Canvas per style)
struct PuzzleArtworkView: View {
    let style: PuzzleArtStyle

    var body: some View {
        Canvas { ctx, size in
            switch style {
            case .mountainSunset: ArtDraw.mountainSunset(ctx, size)
            case .oceanWaves:     ArtDraw.oceanWaves(ctx, size)
            case .geometricGrid:  ArtDraw.geometricGrid(ctx, size)
            case .aurora:         ArtDraw.aurora(ctx, size)
            case .floralMandala:  ArtDraw.floralMandala(ctx, size)
            }
        }
    }
}

// MARK: - Drawing functions
enum ArtDraw {

    // ── Mountain Sunset ────────────────────────────────────────────────────────
    static func mountainSunset(_ ctx: GraphicsContext, _ sz: CGSize) {
        let w = sz.width, h = sz.height

        // Sky
        var sky = Path(); sky.addRect(CGRect(origin: .zero, size: sz))
        ctx.fill(sky, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(hue:0.65,saturation:0.6,brightness:0.18), location:0),
                .init(color: Color(hue:0.05,saturation:0.95,brightness:0.90), location:0.55),
                .init(color: Color(hue:0.10,saturation:0.80,brightness:1.00), location:1.0),
            ]),
            startPoint: .init(x:w/2, y:0), endPoint: .init(x:w/2, y:h)
        ))

        // Sun glow
        ctx.fill(Path { p in p.addEllipse(in: CGRect(x:w*0.35, y:h*0.25, width:w*0.30, height:w*0.30)) },
                 with: .radialGradient(
                    Gradient(colors: [Color(hue:0.10,saturation:0.3,brightness:1.0).opacity(0.5), .clear]),
                    center: .init(x:w*0.5, y:h*0.40), startRadius:0, endRadius:w*0.20
                 ))
        // Sun disk
        ctx.fill(Path { p in p.addEllipse(in: CGRect(x:w*0.44, y:h*0.33, width:w*0.12, height:w*0.12)) },
                 with: .color(Color(hue:0.12,saturation:0.15,brightness:1.0)))

        // Mountains
        let mLayers: [(ys:[(CGFloat,CGFloat)], hue:CGFloat, sat:CGFloat, bri:CGFloat)] = [
            ([(0,0.55),(0.12,0.37),(0.28,0.42),(0.45,0.28),(0.6,0.35),(0.75,0.27),(0.9,0.40),(1,0.55)], 0.72,0.35,0.55),
            ([(0,0.65),(0.08,0.50),(0.22,0.56),(0.40,0.42),(0.55,0.48),(0.70,0.40),(0.85,0.54),(1,0.65)], 0.70,0.45,0.38),
            ([(0,0.78),(0.15,0.63),(0.30,0.70),(0.48,0.57),(0.62,0.65),(0.78,0.60),(0.92,0.72),(1,0.78)], 0.68,0.5,0.22),
            ([(0,0.88),(0.20,0.74),(0.42,0.80),(0.58,0.70),(0.75,0.76),(0.90,0.82),(1,0.88)], 0.0,0.0,0.10),
        ]
        for ml in mLayers {
            var p = Path()
            p.move(to: .init(x:0, y:h))
            for (px,py) in ml.ys { p.addLine(to: .init(x:px*w, y:py*h)) }
            p.addLine(to: .init(x:w, y:h))
            p.closeSubpath()
            ctx.fill(p, with: .color(Color(hue:ml.hue, saturation:ml.sat, brightness:ml.bri)))
        }
    }

    // ── Ocean Waves ─────────────────────────────────────────────────────────
    static func oceanWaves(_ ctx: GraphicsContext, _ sz: CGSize) {
        let w = sz.width, h = sz.height

        // Sky
        var sky = Path(); sky.addRect(CGRect(origin: .zero, size: sz))
        ctx.fill(sky, with: .linearGradient(
            Gradient(colors: [Color(hue:0.59,saturation:0.6,brightness:0.88), Color(hue:0.57,saturation:0.8,brightness:0.55)]),
            startPoint: .init(x:w/2,y:0), endPoint: .init(x:w/2,y:h*0.45)
        ))

        // Sun
        ctx.fill(Path { p in p.addEllipse(in: CGRect(x:w*0.70,y:h*0.05,width:w*0.12,height:w*0.12)) },
                 with: .color(Color(hue:0.12,saturation:0.25,brightness:1.0)))

        // Waves (8 horizontal bands)
        let waveLayers: [(yBase:CGFloat, amp:CGFloat, hue:CGFloat, sat:CGFloat, bri:CGFloat)] = [
            (0.40, 0.03, 0.58, 0.65, 0.75),
            (0.48, 0.03, 0.58, 0.70, 0.70),
            (0.55, 0.04, 0.59, 0.75, 0.65),
            (0.62, 0.035,0.60, 0.80, 0.58),
            (0.70, 0.04, 0.60, 0.82, 0.50),
            (0.78, 0.045,0.61, 0.85, 0.42),
            (0.86, 0.04, 0.61, 0.88, 0.34),
            (0.92, 0.03, 0.62, 0.90, 0.28),
        ]
        for (i, wl) in waveLayers.enumerated() {
            let phase = CGFloat(i) * 0.7
            var p = Path()
            p.move(to: .init(x:0, y:h))
            let steps = 60
            for s in 0...steps {
                let x = CGFloat(s)/CGFloat(steps)*w
                let y = wl.yBase*h + sin(x/w*2*CGFloat.pi*2 + phase)*wl.amp*h
                if s == 0 { p.move(to: .init(x:0, y:y)) } else { p.addLine(to: .init(x:x, y:y)) }
            }
            p.addLine(to: .init(x:w, y:h))
            p.addLine(to: .init(x:0, y:h))
            p.closeSubpath()
            ctx.fill(p, with: .color(Color(hue:wl.hue, saturation:wl.sat, brightness:wl.bri)))

            // Foam highlight on wave crest
            if i < 5 {
                var foam = Path()
                for s in 0...steps {
                    let x = CGFloat(s)/CGFloat(steps)*w
                    let y = wl.yBase*h + sin(x/w*2*CGFloat.pi*2 + phase)*wl.amp*h
                    if s == 0 { foam.move(to: .init(x:0, y:y-2)) } else { foam.addLine(to: .init(x:x, y:y-2)) }
                }
                ctx.stroke(foam, with: .color(.white.opacity(0.35)), lineWidth:2)
            }
        }
    }

    // ── Geometric Grid ──────────────────────────────────────────────────────
    static func geometricGrid(_ ctx: GraphicsContext, _ sz: CGSize) {
        let w = sz.width, h = sz.height
        let cols = 8, rows = 8
        let cw = w / CGFloat(cols), rh = h / CGFloat(rows)

        let palette: [Color] = [
            Color(hue:0.06,saturation:0.90,brightness:0.90),
            Color(hue:0.13,saturation:0.85,brightness:0.95),
            Color(hue:0.30,saturation:0.75,brightness:0.70),
            Color(hue:0.55,saturation:0.80,brightness:0.75),
            Color(hue:0.70,saturation:0.65,brightness:0.80),
            Color(hue:0.83,saturation:0.75,brightness:0.80),
            Color(hue:0.95,saturation:0.70,brightness:0.85),
            Color(hue:0.45,saturation:0.60,brightness:0.70),
        ]

        // Dark base
        var bg = Path(); bg.addRect(CGRect(origin:.zero, size:sz))
        ctx.fill(bg, with: .color(Color(hue:0.65,saturation:0.3,brightness:0.08)))

        let seed: UInt64 = 0x9e3779b9
        for row in 0..<rows {
            for col in 0..<cols {
                let idx = Int((UInt64(row * cols + col) &* seed) % UInt64(palette.count))
                let x = CGFloat(col)*cw, y = CGFloat(row)*rh
                let inner: CGFloat = 4
                var cell = Path()
                cell.addRoundedRect(in: CGRect(x:x+inner,y:y+inner,width:cw-inner*2,height:rh-inner*2),
                                    cornerSize: .init(width:4,height:4))
                // diagonal split
                let useTriangle = (row + col) % 3 == 0
                if useTriangle {
                    var tri = Path()
                    tri.move(to: .init(x:x+inner, y:y+inner))
                    tri.addLine(to: .init(x:x+cw-inner, y:y+inner))
                    tri.addLine(to: .init(x:x+inner, y:y+rh-inner))
                    tri.closeSubpath()
                    ctx.fill(tri, with: .color(palette[idx].opacity(0.9)))
                    let idx2 = (idx + 3) % palette.count
                    var tri2 = Path()
                    tri2.move(to: .init(x:x+cw-inner, y:y+inner))
                    tri2.addLine(to: .init(x:x+cw-inner, y:y+rh-inner))
                    tri2.addLine(to: .init(x:x+inner, y:y+rh-inner))
                    tri2.closeSubpath()
                    ctx.fill(tri2, with: .color(palette[idx2].opacity(0.9)))
                } else {
                    ctx.fill(cell, with: .color(palette[idx].opacity(0.85)))
                }
                // grid line
                ctx.stroke(cell, with: .color(.black.opacity(0.3)), lineWidth:0.5)
            }
        }
    }

    // ── Aurora Borealis ─────────────────────────────────────────────────────
    static func aurora(_ ctx: GraphicsContext, _ sz: CGSize) {
        let w = sz.width, h = sz.height

        // Very dark sky
        var bg = Path(); bg.addRect(CGRect(origin:.zero, size:sz))
        ctx.fill(bg, with: .linearGradient(
            Gradient(colors: [Color(hue:0.62,saturation:0.5,brightness:0.06), Color(hue:0.62,saturation:0.4,brightness:0.04)]),
            startPoint:.init(x:w/2,y:0), endPoint:.init(x:w/2,y:h)
        ))

        // Stars
        let starSeeds: [(CGFloat,CGFloat,CGFloat)] = [
            (0.05,0.10,1.5),(0.18,0.05,1.0),(0.32,0.12,1.8),(0.47,0.07,1.2),(0.61,0.03,1.5),
            (0.73,0.11,1.0),(0.88,0.06,1.8),(0.12,0.20,1.0),(0.55,0.18,1.3),(0.80,0.22,1.0),
            (0.25,0.30,0.8),(0.40,0.25,1.5),(0.92,0.28,0.8),(0.03,0.35,1.2),(0.68,0.33,1.0),
        ]
        for (sx,sy,sr) in starSeeds {
            ctx.fill(Path { p in p.addEllipse(in: CGRect(x:sx*w-sr, y:sy*h-sr, width:sr*2, height:sr*2)) },
                     with: .color(.white.opacity(0.9)))
        }

        // Aurora ribbons
        let ribbons: [(baseY:CGFloat, amp:CGFloat, phase:CGFloat, hue:CGFloat, sat:CGFloat, bri:CGFloat, thick:CGFloat)] = [
            (0.28, 0.10, 0.0,  0.40, 0.90, 0.70, 0.08),
            (0.35, 0.08, 1.2,  0.50, 0.85, 0.75, 0.06),
            (0.42, 0.12, 2.1,  0.75, 0.70, 0.75, 0.07),
            (0.50, 0.09, 0.7,  0.35, 0.90, 0.65, 0.05),
            (0.58, 0.11, 1.8,  0.55, 0.80, 0.70, 0.06),
        ]
        let steps = 80
        for rb in ribbons {
            var top = Path(), bot = Path()
            for s in 0...steps {
                let x = CGFloat(s)/CGFloat(steps)*w
                let yc = rb.baseY*h + sin(x/w*CGFloat.pi*2.5 + rb.phase)*rb.amp*h
                let yt = yc - rb.thick*h/2
                let yb = yc + rb.thick*h/2
                if s==0 { top.move(to:.init(x:x,y:yt)); bot.move(to:.init(x:x,y:yb)) }
                else { top.addLine(to:.init(x:x,y:yt)); bot.addLine(to:.init(x:x,y:yb)) }
            }
            var ribbon = top
            for s in stride(from:steps, through:0, by:-1) {
                let x = CGFloat(s)/CGFloat(steps)*w
                let yc = rb.baseY*h + sin(x/w*CGFloat.pi*2.5 + rb.phase)*rb.amp*h
                let yb = yc + rb.thick*h/2
                ribbon.addLine(to:.init(x:x,y:yb))
            }
            ribbon.closeSubpath()
            ctx.fill(ribbon, with: .linearGradient(
                Gradient(colors: [
                    Color(hue:rb.hue, saturation:rb.sat, brightness:rb.bri).opacity(0.0),
                    Color(hue:rb.hue, saturation:rb.sat, brightness:rb.bri).opacity(0.75),
                    Color(hue:rb.hue, saturation:rb.sat, brightness:rb.bri).opacity(0.0),
                ]),
                startPoint:.init(x:0,y:rb.baseY*h), endPoint:.init(x:w,y:rb.baseY*h)
            ))
        }
    }

    // ── Floral Mandala ──────────────────────────────────────────────────────
    static func floralMandala(_ ctx: GraphicsContext, _ sz: CGSize) {
        let w = sz.width, h = sz.height
        let cx = w/2, cy = h/2

        // Background – deep indigo gradient
        var bg = Path(); bg.addRect(CGRect(origin:.zero, size:sz))
        ctx.fill(bg, with: .linearGradient(
            Gradient(colors: [Color(hue:0.73,saturation:0.75,brightness:0.12), Color(hue:0.70,saturation:0.80,brightness:0.08)]),
            startPoint:.init(x:cx,y:0), endPoint:.init(x:cx,y:h)
        ))

        let petalColors: [Color] = [
            Color(hue:0.05,saturation:0.9,brightness:0.95),
            Color(hue:0.83,saturation:0.8,brightness:0.90),
            Color(hue:0.13,saturation:0.85,brightness:0.95),
            Color(hue:0.60,saturation:0.75,brightness:0.85),
        ]

        // Outer ring of dots
        let dotR = min(w,h)*0.44
        for i in 0..<24 {
            let angle = CGFloat(i)/24.0 * CGFloat.pi * 2
            let dx = cx + dotR * cos(angle)
            let dy = cy + dotR * sin(angle)
            let col = petalColors[i % petalColors.count]
            ctx.fill(Path { p in p.addEllipse(in:CGRect(x:dx-4,y:dy-4,width:8,height:8)) },
                     with: .color(col.opacity(0.7)))
        }

        // Three rings of petals
        let petalRings: [(count:Int, r:CGFloat, petalLen:CGFloat, petalWid:CGFloat, colorIdx:Int, phase:CGFloat)] = [
            (12, min(w,h)*0.34, min(w,h)*0.14, min(w,h)*0.06, 0, 0),
            (8,  min(w,h)*0.22, min(w,h)*0.12, min(w,h)*0.05, 1, CGFloat.pi/8),
            (6,  min(w,h)*0.12, min(w,h)*0.08, min(w,h)*0.04, 2, 0),
        ]
        for ring in petalRings {
            for i in 0..<ring.count {
                let angle = CGFloat(i)/CGFloat(ring.count) * CGFloat.pi * 2 + ring.phase
                let pc = cx + ring.r * cos(angle)
                let ps = cy + ring.r * sin(angle)
                let col = petalColors[(ring.colorIdx + i/2) % petalColors.count]

                var petal = Path()
                petal.move(to: .init(x:pc,y:ps))
                let tipX = pc + ring.petalLen * cos(angle)
                let tipY = ps + ring.petalLen * sin(angle)
                let c1x = pc + ring.petalLen*0.5*cos(angle) - ring.petalWid*sin(angle)
                let c1y = ps + ring.petalLen*0.5*sin(angle) + ring.petalWid*cos(angle)
                let c2x = pc + ring.petalLen*0.5*cos(angle) + ring.petalWid*sin(angle)
                let c2y = ps + ring.petalLen*0.5*sin(angle) - ring.petalWid*cos(angle)
                petal.addCurve(to:.init(x:tipX,y:tipY), control1:.init(x:c1x,y:c1y), control2:.init(x:tipX,y:tipY))
                petal.addCurve(to:.init(x:pc,y:ps), control1:.init(x:c2x,y:c2y), control2:.init(x:pc,y:ps))
                ctx.fill(petal, with: .color(col.opacity(0.85)))
            }
        }

        // Center circle
        ctx.fill(Path { p in p.addEllipse(in:CGRect(x:cx-22,y:cy-22,width:44,height:44)) },
                 with: .color(Color(hue:0.12,saturation:0.9,brightness:1.0)))
        ctx.fill(Path { p in p.addEllipse(in:CGRect(x:cx-10,y:cy-10,width:20,height:20)) },
                 with: .color(.white))
    }
}

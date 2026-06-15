import SwiftUI
import UIKit

/// Pure drawing routines for paper templates, shared by the live SwiftUI
/// `Canvas` background and the off-screen thumbnail / PDF compositing path.
enum PaperRenderer {
    /// Spacing between ruled lines / grid cells, in points.
    static let lineSpacing: CGFloat = 34
    static let gridSpacing: CGFloat = 28
    static let dotSpacing: CGFloat = 26

    // MARK: - SwiftUI Canvas (live background)

    /// Draw the template into a SwiftUI graphics context.
    static func draw(
        in context: inout GraphicsContext,
        size: CGSize,
        template: PaperTemplate,
        lineColor: Color
    ) {
        guard size.width > 0, size.height > 0 else { return }
        switch template {
        case .blank:
            break
        case .ruled:
            var y = lineSpacing
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
                y += lineSpacing
            }
        case .grid:
            var x = gridSpacing
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.8)
                x += gridSpacing
            }
            var y = gridSpacing
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.8)
                y += gridSpacing
            }
        case .dotted:
            var y = dotSpacing
            while y < size.height {
                var x = dotSpacing
                while x < size.width {
                    let r: CGFloat = 1.4
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(lineColor))
                    x += dotSpacing
                }
                y += dotSpacing
            }
        }
    }

    // MARK: - UIKit CoreGraphics (thumbnails / PDF)

    /// Draw the template into the current UIKit graphics context.
    static func drawCG(
        size: CGSize,
        template: PaperTemplate,
        paperColor: UIColor,
        lineColor: UIColor
    ) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              size.width > 0, size.height > 0 else { return }

        // Paper fill
        paperColor.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))

        lineColor.setStroke()
        lineColor.setFill()

        switch template {
        case .blank:
            break
        case .ruled:
            ctx.setLineWidth(1)
            var y = lineSpacing
            while y < size.height {
                ctx.move(to: CGPoint(x: 0, y: y))
                ctx.addLine(to: CGPoint(x: size.width, y: y))
                y += lineSpacing
            }
            ctx.strokePath()
        case .grid:
            ctx.setLineWidth(0.8)
            var x = gridSpacing
            while x < size.width {
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addLine(to: CGPoint(x: x, y: size.height))
                x += gridSpacing
            }
            var y = gridSpacing
            while y < size.height {
                ctx.move(to: CGPoint(x: 0, y: y))
                ctx.addLine(to: CGPoint(x: size.width, y: y))
                y += gridSpacing
            }
            ctx.strokePath()
        case .dotted:
            var y = dotSpacing
            while y < size.height {
                var x = dotSpacing
                while x < size.width {
                    let r: CGFloat = 1.4
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    ctx.fillEllipse(in: rect)
                    x += dotSpacing
                }
                y += dotSpacing
            }
        }
    }
}

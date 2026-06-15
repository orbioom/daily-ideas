import PencilKit
import UIKit

/// Renders page thumbnails off the main render path. A `PKDrawing` is rasterized
/// via `image(from:scale:)` and composited over the paper template.
enum ThumbnailRenderer {
    /// Aspect ratio used for thumbnails and the canvas page (portrait A-ish).
    static let pageAspect: CGFloat = 1.3

    /// Standard reference page size used when rendering a fresh page's bounds.
    static let referenceSize = CGSize(width: 1000, height: 1300)

    /// Render a thumbnail for a page and return PNG data, or nil on failure.
    /// Safe to call on a background queue.
    static func makeThumbnail(
        drawingData: Data,
        template: PaperTemplate,
        paperColor: UIColor,
        lineColor: UIColor,
        targetWidth: CGFloat = 360
    ) -> Data? {
        let size = CGSize(width: targetWidth, height: targetWidth * pageAspect)
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { _ in
            // Paper + template behind the strokes.
            PaperRenderer.drawCG(
                size: size,
                template: template,
                paperColor: paperColor,
                lineColor: lineColor
            )

            // Strokes on top — guard the decode (never try!).
            guard !drawingData.isEmpty,
                  let drawing = try? PKDrawing(data: drawingData) else { return }
            let bounds = drawing.bounds
            guard bounds.width > 0, bounds.height > 0 else { return }

            // Scale the drawing's content area to fit the thumbnail width,
            // anchored at the top-left like the canvas page.
            let scale = size.width / referenceSize.width
            let strokeImage = drawing.image(from: drawing.bounds, scale: 2)
            let drawRect = CGRect(
                x: bounds.minX * scale,
                y: bounds.minY * scale,
                width: bounds.width * scale,
                height: bounds.height * scale
            )
            strokeImage.draw(in: drawRect)
        }

        return image.pngData()
    }
}

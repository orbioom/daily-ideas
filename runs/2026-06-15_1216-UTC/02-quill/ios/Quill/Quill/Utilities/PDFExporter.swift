import PencilKit
import UIKit

/// Renders a notebook's pages into a multi-page PDF for sharing (Pro feature).
enum PDFExporter {
    /// US Letter at 72 dpi.
    static let pageSize = CGSize(width: 612, height: 792)

    struct PageInput {
        let drawingData: Data
        let template: PaperTemplate
    }

    /// Produces a PDF file in the temporary directory and returns its URL,
    /// or nil if there are no pages or writing fails.
    static func export(
        title: String,
        pages: [PageInput],
        paperColor: UIColor,
        lineColor: UIColor
    ) -> URL? {
        guard !pages.isEmpty else { return nil }

        let format = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        let safeTitle = title.isEmpty ? "Notebook" : title
        let fileName = safeTitle
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName.isEmpty ? "Notebook" : fileName)
            .appendingPathExtension("pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                for page in pages {
                    ctx.beginPage()
                    PaperRenderer.drawCG(
                        size: pageSize,
                        template: page.template,
                        paperColor: paperColor,
                        lineColor: lineColor
                    )
                    guard !page.drawingData.isEmpty,
                          let drawing = try? PKDrawing(data: page.drawingData) else { continue }
                    let dBounds = drawing.bounds
                    guard dBounds.width > 0, dBounds.height > 0 else { continue }

                    let scale = pageSize.width / ThumbnailRenderer.referenceSize.width
                    let strokeImage = drawing.image(from: dBounds, scale: 2)
                    let rect = CGRect(
                        x: dBounds.minX * scale,
                        y: dBounds.minY * scale,
                        width: dBounds.width * scale,
                        height: dBounds.height * scale
                    )
                    strokeImage.draw(in: rect)
                }
            }
            return url
        } catch {
            return nil
        }
    }
}

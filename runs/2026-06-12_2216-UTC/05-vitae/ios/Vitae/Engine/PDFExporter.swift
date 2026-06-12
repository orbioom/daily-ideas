import SwiftUI
import UIKit

enum PaperSize: String, CaseIterable, Identifiable {
    case letter, a4

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .letter: return "US Letter"
        case .a4: return "A4"
        }
    }

    /// Page size in PDF points.
    var pointSize: CGSize {
        switch self {
        case .letter: return CGSize(width: 612, height: 792)
        case .a4: return CGSize(width: 595, height: 842)
        }
    }
}

enum PDFExportError: LocalizedError {
    case renderFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed: return "The resume couldn't be rendered. Try a different template."
        case .writeFailed: return "The PDF couldn't be written to disk."
        }
    }
}

/// Renders the SwiftUI document view into a real multi-page PDF.
/// The tall document image is sliced into pages by drawing it at a negative
/// offset inside each page of a UIGraphicsPDFRenderer context.
enum PDFExporter {
    @MainActor
    static func export(resume: Resume, paper: PaperSize) throws -> URL {
        let page = paper.pointSize
        let document = ResumeDocumentView(resume: resume, width: page.width)

        let renderer = ImageRenderer(content: document)
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: page.width, height: nil)
        guard let image = renderer.uiImage, image.size.height > 1 else {
            throw PDFExportError.renderFailed
        }

        let totalHeight = image.size.height
        let pageCount = max(1, Int(ceil(totalHeight / page.height)))

        let bounds = CGRect(origin: .zero, size: page)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)
        let data = pdfRenderer.pdfData { context in
            for pageIndex in 0..<pageCount {
                context.beginPage()
                // White page background (the document view already paints
                // white, but the final partial page may fall short).
                UIColor.white.setFill()
                context.fill(bounds)
                let offsetY = -CGFloat(pageIndex) * page.height
                image.draw(in: CGRect(x: 0, y: offsetY, width: page.width, height: totalHeight))
            }
        }

        let safeName = resume.fullName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let fileName = (safeName.isEmpty ? "Resume" : safeName) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PDFExportError.writeFailed
        }
        return url
    }
}

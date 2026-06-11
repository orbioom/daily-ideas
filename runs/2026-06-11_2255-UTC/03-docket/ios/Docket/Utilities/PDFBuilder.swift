import UIKit
import PDFKit

/// Assembles a shareable PDF from a document's page images, entirely with
/// PDFKit on device.
enum PDFBuilder {
    /// Builds the PDF and writes it to a temporary file named after the
    /// document, returning the URL for ShareLink. Returns `nil` if no page
    /// image could be loaded.
    static func makePDF(for document: ScanDocument) -> URL? {
        let pdf = PDFDocument()
        var index = 0
        for page in document.orderedPages {
            guard let image = ImageStore.load(page.fileName),
                  let pdfPage = PDFPage(image: image) else { continue }
            pdf.insert(pdfPage, at: index)
            index += 1
        }
        guard index > 0, let data = pdf.dataRepresentation() else { return nil }

        let safeName = document.title
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined()
            .trimmingCharacters(in: .whitespaces)
        let fileName = (safeName.isEmpty ? "Document" : safeName) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

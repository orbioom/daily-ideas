import UIKit
import SwiftData
import Observation

/// Turns a batch of captured/imported images into a persisted document:
/// writes JPEGs, creates the SwiftData records, then runs on-device OCR
/// page by page (publishing progress for the UI).
@MainActor
@Observable
final class ScanIngestor {
    enum Status: Equatable {
        case idle
        case saving
        case recognizing(page: Int, of: Int)
        case done
        case failed(String)
    }

    private(set) var status: Status = .idle

    /// Creates the document and kicks off OCR. Returns the new document, or
    /// `nil` if no image could be stored.
    func ingest(images: [UIImage], title: String, quality: CGFloat,
                folder: Folder?, into context: ModelContext) -> ScanDocument? {
        guard !images.isEmpty else {
            status = .failed("The scan contained no pages.")
            return nil
        }
        status = .saving

        var fileNames: [String] = []
        for image in images {
            if let name = ImageStore.save(image, quality: quality) {
                fileNames.append(name)
            }
        }
        guard !fileNames.isEmpty else {
            status = .failed("The pages couldn't be written to storage.")
            return nil
        }

        let document = ScanDocument(title: title)
        document.folder = folder
        context.insert(document)
        for (index, name) in fileNames.enumerated() {
            let page = ScanPage(order: index, fileName: name)
            page.document = document
            context.insert(page)
        }

        let pages = document.orderedPages
        Task { [weak self] in
            for (index, page) in pages.enumerated() {
                self?.status = .recognizing(page: index + 1, of: pages.count)
                if let image = ImageStore.load(page.fileName) {
                    page.ocrText = await OCRService.recognizeText(in: image)
                }
            }
            document.updatedAt = .now
            self?.status = .done
        }
        return document
    }

    /// Appends pages to an existing document and OCRs them.
    func append(images: [UIImage], to document: ScanDocument, quality: CGFloat) {
        guard !images.isEmpty else { return }
        status = .saving
        let startOrder = (document.pages.map(\.order).max() ?? -1) + 1
        guard let context = document.modelContext else {
            status = .failed("The document is no longer available.")
            return
        }
        var newPages: [ScanPage] = []
        for (offset, image) in images.enumerated() {
            if let name = ImageStore.save(image, quality: quality) {
                let page = ScanPage(order: startOrder + offset, fileName: name)
                page.document = document
                context.insert(page)
                newPages.append(page)
            }
        }
        document.updatedAt = .now
        Task { [weak self] in
            for (index, page) in newPages.enumerated() {
                self?.status = .recognizing(page: index + 1, of: newPages.count)
                if let image = ImageStore.load(page.fileName) {
                    page.ocrText = await OCRService.recognizeText(in: image)
                }
            }
            self?.status = .done
        }
    }

    func reset() { status = .idle }
}

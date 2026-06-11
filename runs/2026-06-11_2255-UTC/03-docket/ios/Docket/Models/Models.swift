import Foundation
import SwiftData

@Model
final class Folder {
    var name: String
    var icon: String
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \ScanDocument.folder)
    var documents: [ScanDocument] = []

    init(name: String, icon: String = "folder", createdAt: Date = .now) {
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }
}

@Model
final class ScanDocument {
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var folder: Folder?
    @Relationship(deleteRule: .cascade, inverse: \ScanPage.document)
    var pages: [ScanPage] = []

    init(title: String, createdAt: Date = .now) {
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isFavorite = false
    }

    var orderedPages: [ScanPage] {
        pages.sorted { $0.order < $1.order }
    }

    /// All recognized text across pages, for search.
    var fullText: String {
        orderedPages.map(\.ocrText).joined(separator: "\n")
    }
}

@Model
final class ScanPage {
    var order: Int
    /// File name of the JPEG inside the app's documents/Pages directory.
    var fileName: String
    /// On-device recognized text for this page ("" until OCR completes).
    var ocrText: String
    var document: ScanDocument?

    init(order: Int, fileName: String, ocrText: String = "") {
        self.order = order
        self.fileName = fileName
        self.ocrText = ocrText
    }
}

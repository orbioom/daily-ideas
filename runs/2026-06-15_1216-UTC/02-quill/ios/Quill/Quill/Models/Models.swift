import Foundation
import SwiftData

// MARK: - Folder

/// Optional grouping for notebooks. The UI also surfaces an "All Notebooks" pseudo-folder.
@Model
final class Folder {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Notebook.folder)
    var notebooks: [Notebook]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#4C63D8",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.notebooks = []
    }
}

// MARK: - Notebook

@Model
final class Notebook {
    @Attribute(.unique) var id: UUID
    var title: String
    var coverColorHex: String
    var createdAt: Date
    var updatedAt: Date
    /// Stored raw value of `PaperTemplate`.
    var defaultTemplateRaw: String
    var isFavorite: Bool

    var folder: Folder?

    @Relationship(deleteRule: .cascade, inverse: \Page.notebook)
    var pages: [Page]

    init(
        id: UUID = UUID(),
        title: String,
        coverColorHex: String = "#4C63D8",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        defaultTemplate: PaperTemplate = .ruled,
        isFavorite: Bool = false,
        folder: Folder? = nil
    ) {
        self.id = id
        self.title = title
        self.coverColorHex = coverColorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.defaultTemplateRaw = defaultTemplate.rawValue
        self.isFavorite = isFavorite
        self.folder = folder
        self.pages = []
    }

    /// Typed accessor for the default paper template.
    var defaultTemplate: PaperTemplate {
        get { PaperTemplate(rawValue: defaultTemplateRaw) ?? .ruled }
        set { defaultTemplateRaw = newValue.rawValue }
    }

    var pageCount: Int { pages.count }

    /// Pages ordered by their stable orderIndex.
    var orderedPages: [Page] {
        pages.sorted { $0.orderIndex < $1.orderIndex }
    }
}

// MARK: - Page

@Model
final class Page {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    /// Serialized `PKDrawing.dataRepresentation()`.
    var drawingData: Data
    /// Stored raw value of `PaperTemplate`.
    var templateRaw: String
    /// Cached thumbnail PNG data; nil until first render.
    @Attribute(.externalStorage) var thumbnailData: Data?
    var createdAt: Date
    var updatedAt: Date

    var notebook: Notebook?

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        drawingData: Data = Data(),
        template: PaperTemplate = .ruled,
        thumbnailData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        notebook: Notebook? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.drawingData = drawingData
        self.templateRaw = template.rawValue
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notebook = notebook
    }

    /// Typed accessor for the page's paper template.
    var template: PaperTemplate {
        get { PaperTemplate(rawValue: templateRaw) ?? .ruled }
        set { templateRaw = newValue.rawValue }
    }
}

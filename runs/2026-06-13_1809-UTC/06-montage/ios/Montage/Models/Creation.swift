import Foundation
import SwiftData

/// A saved/exported montage — stored as a JPEG preview for the gallery.
@Model
final class Creation {
    var id: UUID
    var image: Data
    var templateName: String
    var categoryRaw: String
    var createdAt: Date

    init(image: Data, templateName: String, category: TemplateCategory) {
        self.id = UUID()
        self.image = image
        self.templateName = templateName
        self.categoryRaw = category.rawValue
        self.createdAt = Date()
    }

    var category: TemplateCategory { TemplateCategory(rawValue: categoryRaw) ?? .story }
}

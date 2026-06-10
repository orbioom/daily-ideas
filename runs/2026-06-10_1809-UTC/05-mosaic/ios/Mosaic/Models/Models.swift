import Foundation
import SwiftData
import SwiftUI

/// Canvas aspect ratios offered for export.
enum CanvasAspect: String, CaseIterable, Identifiable, Codable {
    case square, portrait45, portrait916, landscape169, story

    var id: String { rawValue }
    var label: String {
        switch self {
        case .square: "1:1"
        case .portrait45: "4:5"
        case .portrait916: "9:16"
        case .landscape169: "16:9"
        case .story: "Story"
        }
    }
    /// width / height
    var ratio: CGFloat {
        switch self {
        case .square: 1
        case .portrait45: 4.0/5.0
        case .portrait916: 9.0/16.0
        case .landscape169: 16.0/9.0
        case .story: 9.0/16.0
        }
    }
    var icon: String {
        switch self {
        case .square: "square"
        case .portrait45: "rectangle.portrait"
        case .portrait916, .story: "iphone"
        case .landscape169: "rectangle"
        }
    }
}

/// Per-cell photographic filters, applied via Core Image.
enum PhotoFilter: String, CaseIterable, Identifiable, Codable {
    case none, mono, noir, sepia, vivid, cool, warm, fade

    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: "Original"
        case .mono: "Mono"
        case .noir: "Noir"
        case .sepia: "Sepia"
        case .vivid: "Vivid"
        case .cool: "Cool"
        case .warm: "Warm"
        case .fade: "Fade"
        }
    }
}

/// A saved collage. Image bytes live on disk (via ImageStore); SwiftData stores
/// only the layout and per-cell settings.
@Model
final class CollageProject {
    var id: UUID
    var name: String
    var templateID: Int
    var aspectRaw: String
    var spacing: Double
    var cornerRadius: Double
    var borderWidth: Double
    var backgroundHex: Int      // 0xRRGGBB
    var createdAt: Date
    var updatedAt: Date
    /// Thumbnail filename for the gallery (rendered on save).
    var thumbnailFile: String?

    @Relationship(deleteRule: .cascade, inverse: \CollageCell.project)
    var cells: [CollageCell] = []

    init(name: String, templateID: Int, aspect: CanvasAspect = .square) {
        self.id = UUID()
        self.name = name
        self.templateID = templateID
        self.aspectRaw = aspect.rawValue
        self.spacing = 8
        self.cornerRadius = 6
        self.borderWidth = 0
        self.backgroundHex = 0xFFFFFF
        self.createdAt = .now
        self.updatedAt = .now
    }

    var aspect: CanvasAspect {
        get { CanvasAspect(rawValue: aspectRaw) ?? .square }
        set { aspectRaw = newValue.rawValue }
    }

    var template: Template { Templates.byID(templateID) }

    var orderedCells: [CollageCell] { cells.sorted { $0.order < $1.order } }

    var filledCount: Int { cells.filter { $0.imageFile != nil }.count }
}

@Model
final class CollageCell {
    var id: UUID
    var order: Int
    var imageFile: String?
    var scale: Double
    var offsetX: Double      // normalized to cell width
    var offsetY: Double
    var filterRaw: String
    var project: CollageProject?

    init(order: Int) {
        self.id = UUID()
        self.order = order
        self.scale = 1.0
        self.offsetX = 0
        self.offsetY = 0
        self.filterRaw = PhotoFilter.none.rawValue
    }

    var filter: PhotoFilter {
        get { PhotoFilter(rawValue: filterRaw) ?? .none }
        set { filterRaw = newValue.rawValue }
    }
}

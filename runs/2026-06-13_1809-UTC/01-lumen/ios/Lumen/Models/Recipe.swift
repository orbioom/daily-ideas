import Foundation
import SwiftData

/// A user-saved adjustment stack ("my preset").
@Model
final class Recipe {
    var id: UUID
    var name: String
    var data: Data          // encoded Adjustments
    var createdAt: Date

    init(name: String, adjustments: Adjustments) {
        self.id = UUID()
        self.name = name
        self.data = (try? JSONEncoder().encode(adjustments)) ?? Data()
        self.createdAt = Date()
    }

    var adjustments: Adjustments {
        (try? JSONDecoder().decode(Adjustments.self, from: data)) ?? .neutral
    }
    func update(_ adj: Adjustments) {
        data = (try? JSONEncoder().encode(adj)) ?? data
    }
}

/// A saved edit in the gallery — a small thumbnail plus the recipe used.
@Model
final class EditRecord {
    var id: UUID
    var thumbnail: Data     // small JPEG preview
    var adjustmentData: Data
    var presetName: String?
    var createdAt: Date

    init(thumbnail: Data, adjustments: Adjustments, presetName: String?) {
        self.id = UUID()
        self.thumbnail = thumbnail
        self.adjustmentData = (try? JSONEncoder().encode(adjustments)) ?? Data()
        self.presetName = presetName
        self.createdAt = Date()
    }

    var adjustments: Adjustments {
        (try? JSONDecoder().decode(Adjustments.self, from: adjustmentData)) ?? .neutral
    }
}

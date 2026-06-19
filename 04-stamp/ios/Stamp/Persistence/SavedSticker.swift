import SwiftData
import Foundation

@Model
final class SavedSticker {
    var id: String
    var name: String
    var createdAt: Date
    var imageData: Data
    var borderColor: String
    var borderWidth: Double
    var backgroundColor: String
    var hasShadow: Bool

    init(name: String, imageData: Data, borderColor: String = "#FFFFFF", borderWidth: Double = 8, backgroundColor: String = "#FFFFFF", hasShadow: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = Date()
        self.imageData = imageData
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.backgroundColor = backgroundColor
        self.hasShadow = hasShadow
    }
}

@Model
final class StampPrefs {
    var hasSeenOnboarding: Bool
    var hapticsEnabled: Bool
    var defaultBorderColor: String
    var defaultBorderWidth: Double
    var isPro: Bool

    init() {
        self.hasSeenOnboarding = false
        self.hapticsEnabled = true
        self.defaultBorderColor = "#FFFFFF"
        self.defaultBorderWidth = 12
        self.isPro = false
    }
}

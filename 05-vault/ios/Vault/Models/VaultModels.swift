import Foundation
import SwiftData

@Model
final class VaultAlbum {
    var id: UUID
    var name: String
    var emoji: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \VaultPhoto.album)
    var photos: [VaultPhoto]

    init(name: String, emoji: String = "📁") {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.createdAt = Date()
        self.sortOrder = 0
        self.photos = []
    }

    var photoCount: Int { photos.count }
    var coverPhotoID: String? { photos.sorted { $0.addedAt > $1.addedAt }.first?.fileID }
}

@Model
final class VaultPhoto {
    var id: UUID
    var fileID: String
    var caption: String
    var addedAt: Date
    var isFavorite: Bool
    var width: Int
    var height: Int
    var album: VaultAlbum?

    init(fileID: String, album: VaultAlbum) {
        self.id = UUID()
        self.fileID = fileID
        self.caption = ""
        self.addedAt = Date()
        self.isFavorite = false
        self.width = 0
        self.height = 0
        self.album = album
    }
}

@Model
final class VaultSettings {
    var onboardingComplete: Bool
    var useBiometrics: Bool
    var pinHash: String
    var autoLockMinutes: Int
    var showPhotoCount: Bool
    var gridColumns: Int

    init() {
        self.onboardingComplete = false
        self.useBiometrics = true
        self.pinHash = ""
        self.autoLockMinutes = 1
        self.showPhotoCount = true
        self.gridColumns = 3
    }
}

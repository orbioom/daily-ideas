import SwiftData
import Foundation

@Model
final class SpriteArtwork {
    var id: String
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var width: Int
    var height: Int
    var pixelData: Data  // JSON [Int] of ARGB hex values, 0 = transparent
    var paletteData: Data  // JSON [String] hex colors

    init(name: String, width: Int, height: Int) {
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.width = width
        self.height = height
        let pixels = [Int](repeating: 0, count: width * height)
        self.pixelData = (try? JSONEncoder().encode(pixels)) ?? Data()
        let palette = ["#000000","#FFFFFF","#FF0000","#00FF00","#0000FF","#FFFF00","#FF8800","#8800FF"]
        self.paletteData = (try? JSONEncoder().encode(palette)) ?? Data()
    }

    func loadPixels() -> [Int] {
        (try? JSONDecoder().decode([Int].self, from: pixelData)) ?? [Int](repeating: 0, count: width * height)
    }

    func savePixels(_ pixels: [Int]) {
        pixelData = (try? JSONEncoder().encode(pixels)) ?? Data()
        modifiedAt = Date()
    }

    func loadPalette() -> [String] {
        (try? JSONDecoder().decode([String].self, from: paletteData)) ?? []
    }

    func savePalette(_ palette: [String]) {
        paletteData = (try? JSONEncoder().encode(palette)) ?? Data()
    }
}

@Model
final class SpritePrefs {
    var hasSeenOnboarding: Bool
    var hapticsEnabled: Bool
    var showGrid: Bool
    var isPro: Bool

    init() {
        self.hasSeenOnboarding = false
        self.hapticsEnabled = true
        self.showGrid = true
        self.isPro = false
    }
}

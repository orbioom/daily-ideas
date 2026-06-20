import SwiftUI
import SwiftData

@Model
final class Palette {
    var name: String
    var createdAt: Date
    var sourceImageData: Data?
    @Relationship(deleteRule: .cascade) var colors: [SwatchColor] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

@Model
final class SwatchColor {
    var hex: String
    var r: Double
    var g: Double
    var b: Double
    var colorName: String
    var sortOrder: Int
    var palette: Palette?

    init(extracted: ExtractedColor, order: Int) {
        self.hex = extracted.hex
        self.r = extracted.r
        self.g = extracted.g
        self.b = extracted.b
        self.colorName = extracted.name
        self.sortOrder = order
    }

    var color: Color {
        Color(red: r, green: g, blue: b)
    }

    var rgbString: String {
        "rgb(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)))"
    }
}

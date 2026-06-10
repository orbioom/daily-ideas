import Foundation
import CoreGraphics

/// A collage template: a set of unit-space rectangles (0...1) describing where
/// each cell sits on the canvas.
struct Template: Identifiable, Hashable {
    let id: Int
    let name: String
    let frames: [CGRect]    // unit space
    var cellCount: Int { frames.count }
}

enum Templates {
    static let all: [Template] = [
        Template(id: 1, name: "Single", frames: [
            CGRect(x: 0, y: 0, width: 1, height: 1)
        ]),
        Template(id: 2, name: "Side by side", frames: [
            CGRect(x: 0, y: 0, width: 0.5, height: 1),
            CGRect(x: 0.5, y: 0, width: 0.5, height: 1)
        ]),
        Template(id: 3, name: "Stacked", frames: [
            CGRect(x: 0, y: 0, width: 1, height: 0.5),
            CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
        ]),
        Template(id: 4, name: "Grid", frames: [
            CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
            CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
            CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
            CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        ]),
        Template(id: 5, name: "Big + two", frames: [
            CGRect(x: 0, y: 0, width: 1, height: 0.6),
            CGRect(x: 0, y: 0.6, width: 0.5, height: 0.4),
            CGRect(x: 0.5, y: 0.6, width: 0.5, height: 0.4)
        ]),
        Template(id: 6, name: "Left + two", frames: [
            CGRect(x: 0, y: 0, width: 0.6, height: 1),
            CGRect(x: 0.6, y: 0, width: 0.4, height: 0.5),
            CGRect(x: 0.6, y: 0.5, width: 0.4, height: 0.5)
        ]),
        Template(id: 7, name: "Three rows", frames: [
            CGRect(x: 0, y: 0, width: 1, height: 1.0/3.0),
            CGRect(x: 0, y: 1.0/3.0, width: 1, height: 1.0/3.0),
            CGRect(x: 0, y: 2.0/3.0, width: 1, height: 1.0/3.0)
        ]),
        Template(id: 8, name: "Two + big", frames: [
            CGRect(x: 0, y: 0, width: 0.5, height: 0.4),
            CGRect(x: 0.5, y: 0, width: 0.5, height: 0.4),
            CGRect(x: 0, y: 0.4, width: 1, height: 0.6)
        ]),
        Template(id: 9, name: "Six grid", frames: [
            CGRect(x: 0, y: 0, width: 1.0/3.0, height: 0.5),
            CGRect(x: 1.0/3.0, y: 0, width: 1.0/3.0, height: 0.5),
            CGRect(x: 2.0/3.0, y: 0, width: 1.0/3.0, height: 0.5),
            CGRect(x: 0, y: 0.5, width: 1.0/3.0, height: 0.5),
            CGRect(x: 1.0/3.0, y: 0.5, width: 1.0/3.0, height: 0.5),
            CGRect(x: 2.0/3.0, y: 0.5, width: 1.0/3.0, height: 0.5)
        ]),
    ]

    static func byID(_ id: Int) -> Template {
        all.first { $0.id == id } ?? all[0]
    }
}

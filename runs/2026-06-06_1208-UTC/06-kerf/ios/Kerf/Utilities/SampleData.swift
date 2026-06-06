import Foundation
import SwiftData

/// Seeds a couple of real-feeling projects so the optimizer has something to chew on.
enum SampleData {
    static func seed(into context: ModelContext) {
        let bookshelf = Project(name: "Walnut Bookshelf", kerfMm: 3)
        bookshelf.notes = "Two uprights, four shelves, plus a top and bottom."
        context.insert(bookshelf)
        let bparts: [(String, Double, Int)] = [
            ("Side upright", 1800, 2),
            ("Shelf", 760, 4),
            ("Top / bottom", 800, 2),
            ("Back rail", 760, 2),
        ]
        for (l, mm, q) in bparts {
            let p = Part(label: l, lengthMm: mm, quantity: q); p.project = bookshelf
            bookshelf.parts.append(p); context.insert(p)
        }
        let bstock: [(String, Double, Int)] = [
            ("Walnut 2.4 m", 2400, 6),
            ("Walnut 3.0 m", 3000, 3),
        ]
        for (l, mm, q) in bstock {
            let s = StockBoard(label: l, lengthMm: mm, quantity: q); s.pricePerBoard = mm == 2400 ? 42 : 55
            s.project = bookshelf; bookshelf.stock.append(s); context.insert(s)
        }

        let frames = Project(name: "Picture Frames (×3)", kerfMm: 2)
        frames.notes = "Mitred frames, two sizes."
        context.insert(frames)
        let fparts: [(String, Double, Int)] = [
            ("Long side", 420, 6),
            ("Short side", 320, 6),
        ]
        for (l, mm, q) in fparts {
            let p = Part(label: l, lengthMm: mm, quantity: q); p.project = frames
            frames.parts.append(p); context.insert(p)
        }
        let fs = StockBoard(label: "Oak moulding 2.1 m", lengthMm: 2100, quantity: 0)
        fs.project = frames; frames.stock.append(fs); context.insert(fs)

        try? context.save()
    }
}

import Foundation
import SwiftData

/// A woodworking project that owns the parts to cut and the stock to cut from.
@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var kerfMm: Double = 3.0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Part.project) var parts: [Part] = []
    @Relationship(deleteRule: .cascade, inverse: \StockBoard.project) var stock: [StockBoard] = []

    init(name: String, kerfMm: Double = 3.0) {
        self.name = name
        self.kerfMm = max(0, kerfMm)
    }

    var orderedParts: [Part] { parts.sorted { $0.lengthMm > $1.lengthMm } }
    var orderedStock: [StockBoard] { stock.sorted { $0.lengthMm > $1.lengthMm } }
    var totalPieces: Int { parts.reduce(0) { $0 + max(0, $1.quantity) } }
    var totalRequiredLength: Double { parts.reduce(0) { $0 + $1.lengthMm * Double(max(0, $1.quantity)) } }

    func makePlan() -> CutOptimizer.Plan {
        let pieceSpecs = parts.map { CutOptimizer.PieceSpec(id: $0.id, label: $0.label, length: $0.lengthMm, quantity: $0.quantity) }
        let stockSpecs = stock.map { CutOptimizer.StockSpec(id: $0.id, label: $0.label, length: $0.lengthMm, quantity: $0.quantity) }
        return CutOptimizer.optimize(pieces: pieceSpecs, stock: stockSpecs, kerf: kerfMm)
    }
}

/// A required cut piece.
@Model
final class Part {
    var id: UUID = UUID()
    var label: String = ""
    var lengthMm: Double = 0
    var quantity: Int = 1
    var project: Project?

    init(label: String, lengthMm: Double, quantity: Int = 1) {
        self.label = label
        self.lengthMm = max(0, lengthMm)
        self.quantity = max(1, quantity)
    }
}

/// An available stock board definition.
@Model
final class StockBoard {
    var id: UUID = UUID()
    var label: String = ""
    var lengthMm: Double = 0
    var quantity: Int = 0     // 0 = unlimited
    var pricePerBoard: Double = 0
    var project: Project?

    init(label: String, lengthMm: Double, quantity: Int = 0) {
        self.label = label
        self.lengthMm = max(0, lengthMm)
        self.quantity = max(0, quantity)
    }
    var isUnlimited: Bool { quantity <= 0 }
}

import Foundation

/// One-dimensional cutting-stock optimizer (best-fit decreasing) that respects
/// saw kerf and limited stock availability. All lengths are in millimetres.
/// Pure value types — fully testable and off the main thread.
enum CutOptimizer {

    struct PieceSpec: Identifiable, Sendable {
        let id: UUID
        var label: String
        var length: Double
        var quantity: Int
    }
    struct StockSpec: Identifiable, Sendable {
        let id: UUID
        var label: String
        var length: Double
        var quantity: Int   // 0 = unlimited
    }
    struct PlacedPiece: Identifiable, Sendable {
        let id = UUID()
        let label: String
        let length: Double
    }
    struct BoardLayout: Identifiable, Sendable {
        let id = UUID()
        let stockLabel: String
        let stockLength: Double
        var pieces: [PlacedPiece]
        let kerf: Double
        /// Length consumed including a kerf per cut.
        var usedLength: Double { pieces.reduce(0) { $0 + $1.length } + kerf * Double(pieces.count) }
        var waste: Double { max(0, stockLength - usedLength) }
        var efficiency: Double { stockLength > 0 ? min(1, pieces.reduce(0) { $0 + $1.length } / stockLength) : 0 }
    }
    struct Plan: Sendable {
        var boards: [BoardLayout] = []
        var unfittable: [PlacedPiece] = []   // longer than any stock
        var shortStock = false               // ran out of available stock
        var totalStock: Double { boards.reduce(0) { $0 + $1.stockLength } }
        var totalUsed: Double { boards.reduce(0) { $0 + $1.pieces.reduce(0) { $0 + $1.length } } }
        var totalWaste: Double { boards.reduce(0) { $0 + $1.waste } }
        var efficiency: Double { totalStock > 0 ? totalUsed / totalStock : 0 }
        var boardsByStock: [(label: String, length: Double, count: Int)] {
            var dict: [String: (Double, Int)] = [:]
            for b in boards {
                let key = "\(b.stockLabel)|\(b.stockLength)"
                let existing = dict[key] ?? (b.stockLength, 0)
                dict[key] = (b.stockLength, existing.1 + 1)
            }
            return dict.map { (key, v) in (String(key.split(separator: "|").first ?? ""), v.0, v.1) }
                .sorted { $0.length > $1.length }
        }
    }

    static func optimize(pieces: [PieceSpec], stock: [StockSpec], kerf: Double) -> Plan {
        var plan = Plan()
        let validStock = stock.filter { $0.length > 0 }
        guard !validStock.isEmpty else {
            // everything is unfittable without stock
            for p in pieces where p.length > 0 {
                for _ in 0..<max(0, p.quantity) { plan.unfittable.append(PlacedPiece(label: p.label, length: p.length)) }
            }
            plan.shortStock = true
            return plan
        }

        // expand and sort longest-first
        var queue: [PlacedPiece] = []
        for p in pieces where p.length > 0 {
            for _ in 0..<max(0, p.quantity) { queue.append(PlacedPiece(label: p.label, length: p.length)) }
        }
        queue.sort { $0.length > $1.length }

        // remaining availability per stock id
        var remaining: [UUID: Int] = [:]
        for s in validStock { remaining[s.id] = s.quantity <= 0 ? Int.max : s.quantity }
        let maxStockLength = validStock.map(\.length).max() ?? 0

        for piece in queue {
            if piece.length > maxStockLength {
                plan.unfittable.append(piece)
                continue
            }
            // best-fit into an open board (tightest remaining that still fits)
            var bestIndex: Int?
            var bestRemaining = Double.greatestFiniteMagnitude
            for (i, board) in plan.boards.enumerated() {
                let free = board.stockLength - board.usedLength
                if free >= piece.length + kerf, free < bestRemaining {
                    bestRemaining = free; bestIndex = i
                }
            }
            if let i = bestIndex {
                plan.boards[i].pieces.append(piece)
                continue
            }
            // open a new board: smallest available stock length that fits the piece
            let candidates = validStock
                .filter { $0.length >= piece.length && (remaining[$0.id] ?? 0) > 0 }
                .sorted { $0.length < $1.length }
            if let chosen = candidates.first {
                var board = BoardLayout(stockLabel: chosen.label, stockLength: chosen.length, pieces: [piece], kerf: kerf)
                _ = board.usedLength
                plan.boards.append(board)
                if let r = remaining[chosen.id], r != Int.max { remaining[chosen.id] = r - 1 }
            } else {
                // a board could fit it but none left in stock
                plan.unfittable.append(piece)
                plan.shortStock = true
            }
        }
        return plan
    }
}

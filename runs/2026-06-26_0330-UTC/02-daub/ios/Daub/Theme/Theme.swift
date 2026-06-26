import SwiftUI

enum DaubTheme {
    static let accent = Color.accentColor
    static let background = Color("DaubBackground")

    static func hexToColor(_ hex: String) -> Color {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return .gray }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

extension PuzzleDefinition {
    func color(forPaletteIndex index: Int) -> Color {
        guard index >= 1, index <= palette.count else { return Color.clear }
        return DaubTheme.hexToColor(palette[index - 1])
    }

    var totalPaintableCells: Int {
        cells.filter { $0 > 0 }.count
    }
}

extension PuzzleProgress {
    func completionFraction(for definition: PuzzleDefinition) -> Double {
        let painted = paintedCells
        guard !painted.isEmpty else { return 0 }
        let total = definition.totalPaintableCells
        guard total > 0 else { return 0 }
        let done = zip(painted, definition.cells).filter { $0.0 > 0 && $0.0 == $0.1 }.count
        return Double(done) / Double(total)
    }

    func isFullyComplete(for definition: PuzzleDefinition) -> Bool {
        let painted = paintedCells
        guard painted.count == definition.cells.count else { return false }
        for (p, c) in zip(painted, definition.cells) {
            if c > 0 && p != c { return false }
        }
        return true
    }
}

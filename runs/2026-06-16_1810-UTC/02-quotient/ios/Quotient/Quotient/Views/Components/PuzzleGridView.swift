import SwiftUI

/// Renders the puzzle grid with proper cage borders. For each cell we compute
/// which of its four edges are cage boundaries (neighbor in a different cage or
/// off-grid) and draw a thick border there; thin grid lines elsewhere.
struct PuzzleGridView: View {
    let puzzle: Puzzle
    let cells: [CellState]
    let selected: Int?
    let related: Set<Int>
    let conflicts: Set<Int>
    let highlightRelated: Bool
    let highlightConflicts: Bool
    let onTap: (Int) -> Void

    private var size: Int { puzzle.size }

    var body: some View {
        GeometryReader { geo in
            let dimension = min(geo.size.width, geo.size.height)
            let cellSize = size > 0 ? dimension / CGFloat(size) : dimension
            ZStack(alignment: .topLeading) {
                ForEach(0..<(size * size), id: \.self) { index in
                    cellView(index: index, cellSize: cellSize)
                        .frame(width: cellSize, height: cellSize)
                        .offset(
                            x: CGFloat(index % max(size, 1)) * cellSize,
                            y: CGFloat(index / max(size, 1)) * cellSize
                        )
                }
            }
            .frame(width: dimension, height: dimension)
            // Outer frame for crisp containment.
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.cageBorder, lineWidth: Theme.thickLine)
                    .frame(width: dimension, height: dimension)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func cellView(index: Int, cellSize: CGFloat) -> some View {
        let state = cells.indices.contains(index) ? cells[index] : CellState()
        let isSelected = selected == index
        let isRelated = highlightRelated && related.contains(index)
        let isConflict = highlightConflicts && conflicts.contains(index)
        let edges = cageEdges(for: index)
        let cage = puzzle.cage(forCell: index)
        let showLabel = cage?.labelCell == index

        ZStack {
            Rectangle()
                .fill(fillColor(isSelected: isSelected, isRelated: isRelated, isConflict: isConflict))

            // Cage label in the top-left cell of the cage.
            if let cage, showLabel {
                Text(cage.label)
                    .font(.system(size: max(cellSize * 0.22, 9), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.leading, 3)
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .accessibilityHidden(true)
            }

            // Value or notes.
            if let value = state.value {
                Text("\(value)")
                    .font(.system(size: cellSize * 0.46, weight: .semibold, design: .rounded))
                    .foregroundStyle(isConflict ? Theme.conflict : Theme.textPrimary)
            } else if !state.notes.isEmpty {
                notesView(notes: state.notes, cellSize: cellSize)
            }
        }
        .overlay(cellBorders(edges: edges, cellSize: cellSize))
        .contentShape(Rectangle())
        .onTapGesture { onTap(index) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(index: index, cage: cage))
        .accessibilityValue(accessibilityValue(state: state, isConflict: isConflict))
        .accessibilityHint("Double tap to select this cell")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Fill & borders

    private func fillColor(isSelected: Bool, isRelated: Bool, isConflict: Bool) -> Color {
        if isConflict { return Theme.conflictFill }
        if isSelected { return Theme.selection }
        if isRelated { return Theme.highlightSoft }
        return Theme.cellFill
    }

    private func cellBorders(edges: CageEdges, cellSize: CGFloat) -> some View {
        ZStack {
            // Thin interior lines everywhere first.
            Rectangle()
                .stroke(Theme.gridLine, lineWidth: Theme.thinLine)
            // Thick lines on cage boundaries.
            Path { path in
                let w = cellSize
                if edges.top    { path.move(to: .zero);            path.addLine(to: CGPoint(x: w, y: 0)) }
                if edges.bottom { path.move(to: CGPoint(x: 0, y: w)); path.addLine(to: CGPoint(x: w, y: w)) }
                if edges.left   { path.move(to: .zero);            path.addLine(to: CGPoint(x: 0, y: w)) }
                if edges.right  { path.move(to: CGPoint(x: w, y: 0)); path.addLine(to: CGPoint(x: w, y: w)) }
            }
            .stroke(Theme.cageBorder, style: StrokeStyle(lineWidth: Theme.thickLine, lineCap: .square))
        }
        .allowsHitTesting(false)
    }

    private func notesView(notes: Set<Int>, cellSize: CGFloat) -> some View {
        let columns = Int(ceil(sqrt(Double(max(size, 1)))))
        return VStack(spacing: 0) {
            ForEach(0..<columns, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { col in
                        let n = row * columns + col + 1
                        Text(n <= size && notes.contains(n) ? "\(n)" : " ")
                            .font(.system(size: max(cellSize * 0.16, 7), weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(2)
    }

    // MARK: Cage edge computation

    private struct CageEdges {
        var top = false
        var bottom = false
        var left = false
        var right = false
    }

    /// An edge is a cage boundary if the neighbor across it belongs to a
    /// different cage (or is off-grid).
    private func cageEdges(for index: Int) -> CageEdges {
        guard size > 0 else { return CageEdges() }
        let map = cageMap
        let row = index / size
        let col = index % size
        let myCage = map.indices.contains(index) ? map[index] : -1

        func cageOf(row r: Int, col c: Int) -> Int {
            guard r >= 0, r < size, c >= 0, c < size else { return -2 } // off-grid
            let i = r * size + c
            return map.indices.contains(i) ? map[i] : -2
        }

        var e = CageEdges()
        e.top    = cageOf(row: row - 1, col: col) != myCage
        e.bottom = cageOf(row: row + 1, col: col) != myCage
        e.left   = cageOf(row: row, col: col - 1) != myCage
        e.right  = cageOf(row: row, col: col + 1) != myCage
        return e
    }

    /// Cached cell -> cage id mapping (computed once per render).
    private var cageMap: [Int] { puzzle.cageIndexByCell() }

    // MARK: Accessibility text

    private func accessibilityLabel(index: Int, cage: Cage?) -> String {
        let row = index / max(size, 1) + 1
        let col = index % max(size, 1) + 1
        var label = "Row \(row), column \(col)"
        if let cage {
            if cage.op == .given {
                label += ", given cell"
            } else {
                label += ", cage target \(cage.target) \(cage.op.accessibleName)"
            }
        }
        return label
    }

    private func accessibilityValue(state: CellState, isConflict: Bool) -> String {
        if let v = state.value {
            return isConflict ? "\(v), conflict" : "\(v)"
        }
        if !state.notes.isEmpty {
            return "notes: " + state.notes.sorted().map(String.init).joined(separator: ", ")
        }
        return "empty"
    }
}

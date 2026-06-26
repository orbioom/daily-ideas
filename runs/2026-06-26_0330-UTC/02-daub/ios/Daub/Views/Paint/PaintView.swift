import SwiftUI
import SwiftData

struct PaintView: View {
    let puzzle: PuzzleDefinition

    @Environment(\.modelContext) private var context
    @Query private var progressList: [PuzzleProgress]
    @Query private var settingsAll: [DaubSettings]

    @State private var selectedColorIndex: Int = 1
    @State private var showCompletionAlert = false
    @State private var startTime = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var settings: DaubSettings? { settingsAll.first }
    var hapticsEnabled: Bool { settings?.hapticsEnabled ?? true }
    var showNumbers: Bool { settings?.showNumbers ?? true }

    var prog: PuzzleProgress {
        if let existing = progressList.first(where: { $0.puzzleId == puzzle.id }) {
            return existing
        }
        let new = PuzzleProgress(puzzleId: puzzle.id, cellCount: puzzle.cells.count)
        context.insert(new)
        try? context.save()
        return new
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            let fraction = prog.completionFraction(for: puzzle)
            HStack {
                Text("\(Int(fraction * 100))% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if prog.isCompleted {
                    Label("Complete!", systemImage: "star.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ProgressView(value: fraction)
                .tint(DaubTheme.accent)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .accessibilityLabel("Puzzle \(Int(fraction * 100))% complete")

            // Grid
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                PaintGridView(
                    puzzle: puzzle,
                    progress: prog,
                    selectedColorIndex: selectedColorIndex,
                    showNumbers: showNumbers,
                    hapticsEnabled: hapticsEnabled,
                    onCellPainted: { checkCompletion() }
                )
                .padding(12)
            }
            .background(Color(.systemGroupedBackground))

            Divider()

            // Palette
            PaletteBar(
                palette: puzzle.palette,
                selected: $selectedColorIndex
            )
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(puzzle.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Clear Puzzle", role: .destructive) {
                        clearPuzzle()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Puzzle options")
            }
        }
        .alert("Puzzle Complete!", isPresented: $showCompletionAlert) {
            Button("Awesome!") {}
        } message: {
            Text("You've finished \"\(puzzle.title)\"! Great work.")
        }
        .onAppear {
            startTime = Date()
            if selectedColorIndex < 1 || selectedColorIndex > puzzle.palette.count {
                selectedColorIndex = 1
            }
        }
        .onDisappear {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            prog.timeSpentSeconds += elapsed
            try? context.save()
        }
    }

    private func checkCompletion() {
        if !prog.isCompleted && prog.isFullyComplete(for: puzzle) {
            prog.isCompleted = true
            prog.completedAt = Date()
            try? context.save()
            if !reduceMotion {
                showCompletionAlert = true
            }
        }
    }

    private func clearPuzzle() {
        let empty = [Int](repeating: 0, count: puzzle.cells.count)
        prog.paintedCells = empty
        prog.isCompleted = false
        prog.completedAt = nil
        try? context.save()
    }
}

struct PaintGridView: View {
    let puzzle: PuzzleDefinition
    let progress: PuzzleProgress
    let selectedColorIndex: Int
    let showNumbers: Bool
    let hapticsEnabled: Bool
    let onCellPainted: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cellSize: CGFloat = 44

    var body: some View {
        let painted = progress.paintedCells

        VStack(spacing: 1) {
            ForEach(0..<puzzle.gridHeight, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<puzzle.gridWidth, id: \.self) { col in
                        let idx = row * puzzle.gridWidth + col
                        let def = puzzle.cells[idx]
                        let paintedVal = painted.count > idx ? painted[idx] : 0
                        let isFilled = paintedVal == def && def > 0

                        PaintCell(
                            definedColor: def > 0 ? puzzle.color(forPaletteIndex: def) : nil,
                            paintedColor: paintedVal > 0 ? puzzle.color(forPaletteIndex: paintedVal) : nil,
                            number: (def > 0 && !isFilled && showNumbers) ? def : nil,
                            isBackground: def == 0,
                            size: cellSize
                        )
                        .onTapGesture {
                            guard def > 0 else { return }
                            paintCell(at: idx, def: def)
                        }
                        .accessibilityLabel(accessibilityLabel(row: row, col: col, def: def, paintedVal: paintedVal))
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
        .background(Color(.systemGray4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func paintCell(at idx: Int, def: Int) {
        var cells = progress.paintedCells
        while cells.count < puzzle.cells.count { cells.append(0) }

        if cells[idx] == selectedColorIndex {
            cells[idx] = 0
        } else {
            cells[idx] = selectedColorIndex
            if hapticsEnabled {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            }
        }
        progress.paintedCells = cells
        try? progress.modelContext?.save()
        onCellPainted()
    }

    private func accessibilityLabel(row: Int, col: Int, def: Int, paintedVal: Int) -> String {
        if def == 0 { return "Background cell, row \(row+1), column \(col+1)" }
        let filled = paintedVal == def ? "filled" : "unfilled, color \(def)"
        return "Cell row \(row+1), column \(col+1), \(filled)"
    }
}

private struct PaintCell: View {
    let definedColor: Color?
    let paintedColor: Color?
    let number: Int?
    let isBackground: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if isBackground {
                Color.clear
            } else if let pc = paintedColor {
                pc
            } else {
                Color(.systemGray6)
                if let n = number {
                    Text("\(n)")
                        .font(.system(size: max(8, size * 0.32), weight: .semibold))
                        .foregroundStyle(Color(.systemGray2))
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct PaletteBar: View {
    let palette: [String]
    @Binding var selected: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(1...palette.count, id: \.self) { i in
                    let color = DaubTheme.hexToColor(palette[i - 1])
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(selected == i ? Color.primary : Color.clear, lineWidth: 3)
                                    .padding(-2)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 3)
                        Text("\(i)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                    .onTapGesture { selected = i }
                    .scaleEffect(selected == i ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2), value: selected)
                    .accessibilityLabel("Color \(i)")
                    .accessibilityAddTraits(selected == i ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }
}

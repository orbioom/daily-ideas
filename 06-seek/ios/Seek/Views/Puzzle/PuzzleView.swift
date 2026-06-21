import SwiftUI
import SwiftData

struct PuzzleView: View {
    let category: WordCategory
    let difficulty: PuzzleDifficulty

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [SeekSettings]
    @State private var vm: PuzzleViewModel
    @State private var showComplete = false

    private var settings: SeekSettings { settingsList.first ?? SeekSettings() }

    init(category: WordCategory, difficulty: PuzzleDifficulty) {
        self.category = category
        self.difficulty = difficulty
        _vm = State(initialValue: PuzzleViewModel(category: category, difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            SeekTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                wordList
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                Spacer(minLength: 0)
                gridView
                    .padding(.horizontal, 8)
                Spacer(minLength: 8)
            }
        }
        .onChange(of: vm.isComplete) { _, complete in
            if complete { saveRecord(); showComplete = true }
        }
        .alert("Puzzle Complete! 🎉", isPresented: $showComplete) {
            Button("New Puzzle") {
                vm.newPuzzle(category: category, difficulty: difficulty)
            }
            Button("Choose Category") { dismiss() }
        } message: {
            Text("You found all \(vm.puzzle.placedWords.count) words in \(vm.formattedTime)!")
        }
    }

    var topBar: some View {
        HStack {
            Button { vm.stopTimer(); dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(SeekTheme.textSecondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(category.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SeekTheme.textPrimary)
                Text("\(difficulty.rawValue) · \(difficulty.gridSize)×\(difficulty.gridSize)")
                    .font(.system(size: 12))
                    .foregroundStyle(SeekTheme.textSecondary)
            }
            Spacer()
            if settings.showTimer {
                VStack(spacing: 2) {
                    Text(vm.formattedTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(SeekTheme.accent)
                    Text("\(vm.puzzle.foundCount)/\(vm.puzzle.placedWords.count)")
                        .font(.system(size: 12))
                        .foregroundStyle(SeekTheme.textSecondary)
                }
            }
        }
    }

    var wordList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(vm.puzzle.placedWords.enumerated()), id: \.offset) { _, pw in
                    Text(pw.word)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(pw.isFound ? .black : SeekTheme.textPrimary)
                        .strikethrough(pw.isFound)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            pw.isFound
                                ? SeekTheme.highlightColors[pw.foundColorIndex % SeekTheme.highlightColors.count]
                                : SeekTheme.surface,
                            in: Capsule()
                        )
                }
            }
        }
    }

    var gridView: some View {
        GeometryReader { geo in
            let size = geo.size.width
            let cellSize = size / CGFloat(vm.puzzle.size)
            Canvas { ctx, _ in
                drawGrid(ctx: ctx, cellSize: cellSize)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let col = Int(val.location.x / cellSize)
                        let row = Int(val.location.y / cellSize)
                        let s = vm.puzzle.size
                        guard 0 <= row && row < s && 0 <= col && col < s else { return }
                        if !vm.isDragging { vm.startDrag(row: row, col: col) }
                        else { vm.updateDrag(row: row, col: col) }
                    }
                    .onEnded { _ in vm.endDrag() }
            )
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    func drawGrid(ctx: GraphicsContext, cellSize: CGFloat) {
        let s = vm.puzzle.size
        let cs = cellSize

        // Draw found word highlights
        for pw in vm.puzzle.placedWords where pw.isFound {
            let color = SeekTheme.highlightColors[pw.foundColorIndex % SeekTheme.highlightColors.count]
            for cell in pw.cells {
                let rect = CGRect(
                    x: CGFloat(cell.col) * cs + 2,
                    y: CGFloat(cell.row) * cs + 2,
                    width: cs - 4, height: cs - 4
                )
                ctx.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(color.opacity(0.7)))
            }
        }

        // Draw selection
        for cell in vm.selectedCells {
            let rect = CGRect(
                x: CGFloat(cell.col) * cs + 2,
                y: CGFloat(cell.row) * cs + 2,
                width: cs - 4, height: cs - 4
            )
            ctx.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(SeekTheme.selectionColor.opacity(0.4)))
        }

        // Draw letters
        for r in 0..<s {
            for c in 0..<s {
                let letter = String(vm.puzzle.grid[r][c])
                let cell = (row: r, col: c)
                let isSelected = vm.selectedCells.contains(where: { $0.row == r && $0.col == c })
                let isFound = vm.foundColorIndex(for: cell) != nil

                let color: Color = isSelected ? SeekTheme.textPrimary : (isFound ? .black : SeekTheme.textPrimary)
                let x = CGFloat(c) * cs + cs/2
                let y = CGFloat(r) * cs + cs/2

                let fontSize = max(10, min(20, cs * 0.55))
                let font = Font.system(size: fontSize, weight: .bold, design: .monospaced)
                ctx.draw(
                    Text(letter).font(font).foregroundColor(color),
                    at: CGPoint(x: x, y: y)
                )
            }
        }
    }

    func saveRecord() {
        let record = PuzzleRecord(
            category: category.name,
            difficulty: difficulty.rawValue,
            wordsFound: vm.puzzle.foundCount,
            totalWords: vm.puzzle.placedWords.count,
            timeSeconds: vm.elapsedSeconds,
            completed: vm.puzzle.isComplete
        )
        modelContext.insert(record)
    }
}

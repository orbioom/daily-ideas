import SwiftUI
import SwiftData

struct GalleryView: View {
    @Query private var progressList: [PuzzleProgress]
    @Query private var settingsAll: [DaubSettings]

    @State private var selectedCategory: PuzzleCategory? = nil

    var filteredPuzzles: [PuzzleDefinition] {
        PuzzleCatalog.all.filter { selectedCategory == nil || $0.category == selectedCategory }
    }

    func progress(for puzzle: PuzzleDefinition) -> PuzzleProgress? {
        progressList.first { $0.puzzleId == puzzle.id }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterBar(selected: $selectedCategory)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredPuzzles) { puzzle in
                            NavigationLink {
                                PaintView(puzzle: puzzle)
                            } label: {
                                PuzzleCard(puzzle: puzzle, progress: progress(for: puzzle))
                            }
                            .tint(.primary)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Daub")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct CategoryFilterBar: View {
    @Binding var selected: PuzzleCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", icon: "square.grid.2x2", isSelected: selected == nil) {
                    selected = nil
                }
                ForEach(PuzzleCategory.allCases, id: \.self) { cat in
                    FilterChip(label: cat.rawValue, icon: cat.icon, isSelected: selected == cat) {
                        selected = selected == cat ? nil : cat
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? DaubTheme.accent : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PuzzleCard: View {
    let puzzle: PuzzleDefinition
    let progress: PuzzleProgress?

    var fraction: Double {
        progress.map { $0.completionFraction(for: puzzle) } ?? 0
    }

    var isCompleted: Bool {
        progress.map { $0.isCompleted } ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color(.secondarySystemBackground)
                MiniPreviewCanvas(puzzle: puzzle, progress: progress)
                    .padding(8)
                if isCompleted {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .background(Circle().fill(.white).padding(2))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(puzzle.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label(puzzle.category.rawValue, systemImage: puzzle.category.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(fraction * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(fraction > 0 ? DaubTheme.accent : .secondary)
                }
                ProgressView(value: fraction)
                    .tint(DaubTheme.accent)
                    .scaleEffect(y: 0.7, anchor: .center)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(puzzle.title), \(puzzle.category.rawValue), \(Int(fraction * 100))% complete\(isCompleted ? ", completed" : "")")
    }
}

struct MiniPreviewCanvas: View {
    let puzzle: PuzzleDefinition
    let progress: PuzzleProgress?

    var body: some View {
        Canvas { ctx, size in
            let cw = size.width / CGFloat(puzzle.gridWidth)
            let ch = size.height / CGFloat(puzzle.gridHeight)
            let painted = progress?.paintedCells ?? []

            for row in 0..<puzzle.gridHeight {
                for col in 0..<puzzle.gridWidth {
                    let def = puzzle.cell(row: row, col: col)
                    if def == 0 { continue }
                    let paintedVal = painted.count > row * puzzle.gridWidth + col
                        ? painted[row * puzzle.gridWidth + col] : 0
                    let rect = CGRect(x: CGFloat(col) * cw, y: CGFloat(row) * ch, width: cw, height: ch)
                    if paintedVal == def {
                        ctx.fill(Path(rect), with: .color(puzzle.color(forPaletteIndex: def)))
                    } else {
                        ctx.fill(Path(rect), with: .color(Color(.systemGray5)))
                        ctx.stroke(Path(rect), with: .color(Color(.systemGray3)), lineWidth: 0.5)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

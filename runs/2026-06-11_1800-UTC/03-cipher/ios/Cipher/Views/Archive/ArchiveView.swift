import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Query private var allProgress: [PuzzleProgress]
    @State private var selectedPuzzle: CryptoPuzzle? = nil

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            List {
                ForEach(CryptoPuzzle.catalog.reversed()) { puzzle in
                    let progress = allProgress.first { $0.puzzleId == puzzle.id }
                    ArchiveRow(puzzle: puzzle, progress: progress)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPuzzle = puzzle }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CipherTheme.bg)
            .navigationTitle("Archive")
            .navigationDestination(item: $selectedPuzzle) { puzzle in
                PuzzleView(puzzle: puzzle)
            }
        }
    }
}

extension CryptoPuzzle: Identifiable {}

private struct ArchiveRow: View {
    let puzzle: CryptoPuzzle
    let progress: PuzzleProgress?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: statusIcon)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(puzzle.theme)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CipherTheme.text)
                Text(puzzle.author)
                    .font(.caption)
                    .foregroundStyle(CipherTheme.subtle)
            }

            Spacer()

            if let p = progress {
                if p.isSolved {
                    Text(timeString(p.elapsedSeconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(CipherTheme.solved)
                } else {
                    Text("\(Int(p.letterMapping.count * 100 / max(1, 26)))%")
                        .font(.caption)
                        .foregroundStyle(CipherTheme.amber)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(puzzle.theme) by \(puzzle.author), \(progress?.isSolved == true ? "solved" : "unsolved")")
    }

    private var statusColor: Color {
        if progress?.isSolved == true { return CipherTheme.solved }
        if progress != nil { return CipherTheme.amber }
        return CipherTheme.subtle
    }

    private var statusIcon: String {
        if progress?.isSolved == true { return "checkmark.circle.fill" }
        if progress != nil { return "ellipsis.circle.fill" }
        return "circle"
    }

    private func timeString(_ sec: Int) -> String {
        let m = sec / 60; let s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
}

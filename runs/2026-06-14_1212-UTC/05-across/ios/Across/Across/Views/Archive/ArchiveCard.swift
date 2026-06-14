import SwiftUI

/// One puzzle tile in the archive grid.
struct ArchiveCard: View {
    let puzzle: Puzzle
    let progress: PuzzleProgress?
    let locked: Bool

    private var solved: Bool { progress?.completed ?? false }
    private var inProgress: Bool { !(progress?.completed ?? false) && (progress?.elapsedSeconds ?? 0) > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                MiniGridPreview(grid: puzzle.grid, solved: solved && !locked, side: 56)
                Spacer()
                statusIcon
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(puzzle.title)
                    .font(Theme.serif(17, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(puzzle.size)×\(puzzle.size) \(puzzle.kindLabel)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }

            HStack {
                DifficultyTag(difficulty: puzzle.difficulty)
                Spacer()
                if locked {
                    Label("Pro", systemImage: "lock.fill")
                        .font(Theme.mono(10, .bold))
                        .foregroundStyle(Theme.inkFaint)
                } else if solved, let secs = progress?.elapsedSeconds {
                    Label(TimeFormat.clock(secs), systemImage: "stopwatch")
                        .font(Theme.mono(11, .semibold))
                        .foregroundStyle(Theme.good)
                } else if inProgress {
                    Text("In progress")
                        .font(Theme.mono(10, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(solved ? Theme.good.opacity(0.4) : Theme.hairline, lineWidth: 1)
        )
        .opacity(locked ? 0.7 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if locked {
            Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
        } else if solved {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
        } else if inProgress {
            Image(systemName: "pause.circle.fill").foregroundStyle(Theme.accent)
        } else {
            Image(systemName: "circle").foregroundStyle(Theme.inkFaint)
        }
    }

    private var accessibilityText: String {
        var parts = [puzzle.title, "\(puzzle.size) by \(puzzle.size)", puzzle.difficulty.title]
        if locked { parts.append("locked, Pro required") }
        else if solved, let s = progress?.elapsedSeconds { parts.append("solved in \(TimeFormat.compact(s))") }
        else if inProgress { parts.append("in progress") }
        else { parts.append("not started") }
        return parts.joined(separator: ", ")
    }
}

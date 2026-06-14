import SwiftUI

/// A static, well-designed techniques guide. Teaches the same techniques the hint engine
/// uses, so hints feel like a lesson rather than a giveaway.
struct LearnView: View {
    private struct Technique: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let level: String
        let summary: String
        let detail: String
        let tint: Color
    }

    private let techniques: [Technique] = [
        Technique(icon: "1.circle.fill", title: "Naked Single", level: "Beginner",
                  summary: "A cell with only one possible digit.",
                  detail: "Look at a single empty cell. Cross out every digit that already appears in its row, column, or 3×3 box. If exactly one digit remains, it must go there. This is the most fundamental move and the backbone of Easy puzzles.",
                  tint: Theme.success),
        Technique(icon: "eye.fill", title: "Hidden Single", level: "Beginner",
                  summary: "A digit that fits only one cell in a unit.",
                  detail: "Pick a digit and a unit (row, column, or box). If that digit can legally go in only one cell of the unit — even if that cell has other candidates — then it must go there. It's 'hidden' because the cell looks like it has choices, but the unit forces the digit.",
                  tint: Theme.accent),
        Technique(icon: "arrow.up.left.and.arrow.down.right", title: "Locked Candidates", level: "Intermediate",
                  summary: "Pointing & claiming eliminations.",
                  detail: "Pointing: if a digit's only spots within a box all sit in one row (or column), that digit can be removed from the rest of that row (or column). Claiming: if a digit's only spots within a row (or column) all sit in one box, remove it from the rest of that box. These eliminations often unlock a hidden or naked single.",
                  tint: Theme.warning),
        Technique(icon: "square.on.square", title: "Naked & Hidden Pairs", level: "Advanced",
                  summary: "Two cells, two digits, locked together.",
                  detail: "Naked pair: two cells in a unit share the exact same two candidates — those two digits belong to those two cells, so remove them from every other cell in the unit. Hidden pair: two digits can only go in the same two cells of a unit — so those cells are restricted to just that pair, and any other candidates there can be erased.",
                  tint: Theme.error),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    intro
                    ForEach(techniques) { t in
                        techniqueCard(t)
                    }
                    footerNote
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Learn")
        }
    }

    private var intro: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label("How Nonet Grades Puzzles", systemImage: "graduationcap.fill")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Every puzzle is graded by the hardest technique it requires. Easy needs only singles, Medium adds locked candidates, and Hard/Expert add pairs. The Hint button uses these same techniques and explains each step.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func techniqueCard(_ t: Technique) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: t.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(t.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title)
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(t.level)
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(t.tint)
                    }
                    Spacer()
                }
                Text(t.summary)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(t.detail)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(t.title), \(t.level). \(t.summary). \(t.detail)")
    }

    private var footerNote: some View {
        Text("Tip: turn on Auto Candidates in Settings to see pencil marks computed for you while you learn to spot these patterns.")
            .font(Theme.rounded(13))
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
}

import SwiftUI

/// The Pro "hints page": a two-way grid of word counts by first letter × length,
/// plus pangram and remaining-word summaries.
struct HintsView: View {
    let puzzle: Puzzle
    let foundWords: Set<String>

    @Environment(\.dismiss) private var dismiss
    private var grid: HintGrid { HintGridBuilder.build(puzzle: puzzle, foundWords: foundWords) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        summary
                        gridCard
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Hints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summary: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Today's puzzle")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                summaryRow("Total words", "\(grid.totalWords)")
                summaryRow("Words remaining", "\(grid.totalRemaining)")
                summaryRow("Pangrams", "\(grid.pangramCount)")
                summaryRow("Pangrams remaining", "\(grid.pangramsRemaining)")
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var gridCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Words by first letter and length")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Counts show every word in the puzzle. Tap nothing — just a map of what's out there.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 4)

                ScrollView(.horizontal, showsIndicators: true) {
                    Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                        headerRow
                        ForEach(grid.letters, id: \.self) { letter in
                            row(for: letter)
                        }
                        totalsRow
                    }
                }
            }
        }
    }

    private var headerRow: some View {
        GridRow {
            cell("", header: true)
            ForEach(grid.lengths, id: \.self) { len in
                cell("\(len)", header: true)
            }
            cell("Σ", header: true)
        }
    }

    private func row(for letter: Character) -> some View {
        GridRow {
            cell(String(letter).uppercased(), header: true)
            ForEach(grid.lengths, id: \.self) { len in
                let n = grid.count(letter, len)
                cell(n == 0 ? "–" : "\(n)", muted: n == 0)
            }
            cell("\(grid.rowTotal(letter))", emphasized: true)
        }
    }

    private var totalsRow: some View {
        GridRow {
            cell("Σ", header: true)
            ForEach(grid.lengths, id: \.self) { len in
                cell("\(grid.columnTotal(len))", emphasized: true)
            }
            cell("\(grid.totalWords)", emphasized: true)
        }
    }

    private func cell(_ text: String, header: Bool = false, emphasized: Bool = false, muted: Bool = false) -> some View {
        Text(text)
            .font(Theme.rounded(14, header || emphasized ? .bold : .regular))
            .foregroundStyle(muted ? Theme.inkSoft.opacity(0.5) : (header ? Theme.accentDeep : Theme.ink))
            .frame(width: 34, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(header ? Theme.surfaceAlt : (emphasized ? Theme.surfaceAlt.opacity(0.6) : Color.clear))
            )
            .monospacedDigit()
            .accessibilityHidden(text == "–")
    }
}

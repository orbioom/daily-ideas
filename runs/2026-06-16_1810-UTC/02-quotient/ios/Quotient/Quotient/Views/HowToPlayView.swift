import SwiftUI

/// Explains the rules of Calcudoku with a worked mini-example.
struct HowToPlayView: View {
    // A tiny worked 3×3 example (not playable — illustrative only).
    // Solution:
    // 2 3 1
    // 1 2 3
    // 3 1 2
    private let exampleSize = 3
    private let exampleSolution = [2, 3, 1, 1, 2, 3, 3, 1, 2]
    private let exampleCages: [Cage] = [
        Cage(id: 0, cells: [0, 1], op: .add, target: 5),       // 2+3
        Cage(id: 1, cells: [2, 5], op: .multiply, target: 3),  // 1×3
        Cage(id: 2, cells: [3, 4], op: .subtract, target: 1),  // |1-2|
        Cage(id: 3, cells: [6, 7], op: .add, target: 4),       // 3+1
        Cage(id: 4, cells: [8], op: .given, target: 2)         // given 2
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    rulesCard
                    exampleCard
                    operatorsCard
                    tipsCard
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var intro: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label("The idea", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text("Quotient is an arithmetic logic puzzle. Fill the grid so each row and column contains every number from 1 to N exactly once — and each outlined cage reaches its target using the printed operation.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var rulesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rules")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                rule("1", "Each row uses the numbers 1…N once.")
                rule("2", "Each column uses the numbers 1…N once.")
                rule("3", "Each cage's cells combine with its operation to equal the target.")
                rule("4", "A single-cell cage just shows its given value.")
            }
        }
    }

    private func rule(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Theme.accent))
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var exampleCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Worked example")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("A solved 3×3. The top-left cage 5+ means its two cells add to 5 (here 2 and 3). The 1− cage means the two cells differ by 1.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                PuzzleGridView(
                    puzzle: Puzzle(size: exampleSize, solution: exampleSolution, cages: exampleCages),
                    cells: exampleSolution.map { CellState(value: $0) },
                    selected: nil,
                    related: [],
                    conflicts: [],
                    highlightRelated: false,
                    highlightConflicts: false,
                    onTap: { _ in }
                )
                .frame(height: 180)
                .accessibilityHidden(true)
            }
        }
    }

    private var operatorsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Operators")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                operatorRow("+", "Add", "The cells sum to the target.")
                operatorRow("−", "Subtract", "The difference between two cells equals the target.")
                operatorRow("×", "Multiply", "The cells multiply to the target.")
                operatorRow("÷", "Divide", "One cell divided by the other equals the target.")
            }
        }
    }

    private func operatorRow(_ symbol: String, _ name: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Text(symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(detail)")
    }

    private var tipsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label("Tips", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text("• Use Notes to pencil in candidates.\n• Tap a cell to highlight its row, column, and cage.\n• A Hint reveals one correct cell or fixes a wrong one.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }
}

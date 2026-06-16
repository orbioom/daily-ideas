import SwiftUI

/// The rules guide with an annotated worked example. Reachable as its own tab and from
/// Settings.
struct HowToPlayView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        intro
                        rulesCard
                        exampleCard
                        tipsCard
                    }
                    .padding(18)
                }
            }
            .navigationTitle("How to Play")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Read the clues, fill the cells")
                .font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
            Text("A nonogram hides a picture in a grid. The numbers beside each row and above each column tell you the lengths of the filled runs — in order, with at least one empty cell between runs.")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "The rules", systemImage: "list.bullet")
            rule("square.fill", "Tap a cell to fill it. The clue \u{201C}3\u{201D} means three filled cells in a row.")
            rule("xmark", "Switch to Cross mode (or use the toggle) to mark cells you know are empty.")
            rule("number", "A clue like \u{201C}2 1\u{201D} means a run of 2, then a gap, then a run of 1 — in that order.")
            rule("checkmark.seal.fill", "Fill every cell the clues require and the picture appears. That's a solve.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private func rule(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.accent).frame(width: 22)
                .accessibilityHidden(true)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Worked example

    private var exampleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "A worked example", systemImage: "lightbulb.fill")
            Text("Clue \u{201C}5\u{201D} on a row of 5 cells: every cell must be filled.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            ExampleStrip(states: [.filled, .filled, .filled, .filled, .filled], clue: "5")

            Text("Clue \u{201C}3\u{201D} on a row of 5: the middle cell is always filled — that's the overlap, the heart of the solver.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ExampleStrip(states: [.unknown, .unknown, .filled, .unknown, .unknown], clue: "3")

            Text("Clue \u{201C}2 1\u{201D} on a row of 5: the only fit is fill, fill, cross, cross, fill.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ExampleStrip(states: [.filled, .filled, .crossed, .crossed, .filled], clue: "2 1")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tips", systemImage: "sparkles")
            rule("lightbulb.fill", "Stuck? The Hint button finds one cell that's logically certain — never a guess.")
            rule("xmark.square.fill", "Cross out cells you've ruled out. It keeps lines readable and prevents mistakes.")
            rule("checkmark.circle.fill", "Turn on Assist in Settings to be warned the moment you fill a wrong cell.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }
}

/// A small horizontal strip of example cells with a clue label, for the guide.
struct ExampleStrip: View {
    let states: [CellState]
    let clue: String

    var body: some View {
        HStack(spacing: 8) {
            Text(clue)
                .font(Theme.mono(14, .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 36, alignment: .trailing)
            HStack(spacing: 3) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                    CellTile(state: state, size: 34, isHint: false, isWrong: false, reduceMotion: true)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clue \(clue): " + states.map { $0.accessibilityValue }.joined(separator: ", "))
    }
}

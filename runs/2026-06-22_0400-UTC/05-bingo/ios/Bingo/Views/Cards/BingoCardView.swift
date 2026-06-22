import SwiftUI
import SwiftData

struct BingoCardView: View {
    @Bindable var card: SavedCard
    let calledItems: [String]
    let enabledPatterns: [String]
    let hapticsEnabled: Bool

    var wins: [WinPattern] {
        WinDetector.checkWins(
            grid: card.cells,
            marked: card.marked,
            enabledPatterns: enabledPatterns
        )
    }

    var hasWon: Bool { !wins.isEmpty }

    var body: some View {
        VStack(spacing: 4) {
            // Card label row
            HStack {
                Text(card.label)
                    .font(.headline.bold())
                    .foregroundColor(BingoTheme.gold)
                Spacer()
                if hasWon {
                    Text("BINGO!")
                        .font(.headline.bold())
                        .foregroundColor(BingoTheme.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(BingoTheme.red.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 8)

            // B-I-N-G-O header row
            HStack(spacing: 2) {
                ForEach(["B", "I", "N", "G", "O"], id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(BingoTheme.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(BingoTheme.navy)
                }
            }
            .background(BingoTheme.navy)

            // 5x5 grid
            VStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { col in
                            cellView(row: row, col: col)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(hasWon ? BingoTheme.gold.opacity(0.15) : BingoTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasWon ? BingoTheme.gold : BingoTheme.lightNavy, lineWidth: hasWon ? 2 : 1)
        )
    }

    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        let cellText = getCellText(row: row, col: col)
        let isFree = cellText == "FREE"
        let isMarked = getMarked(row: row, col: col)
        let isCalled = isFree || calledItems.contains(cellText)
        let isWinningCell = WinDetector.isWinningCell(row: row, col: col, patterns: wins)

        Button(action: {
            toggleCell(row: row, col: col)
        }) {
            Text(cellText)
                .font(.system(size: cellFontSize(for: cellText), weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(cellTextColor(isFree: isFree, isMarked: isMarked, isWinningCell: isWinningCell))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(cellBackground(isFree: isFree, isMarked: isMarked, isWinningCell: isWinningCell, isCalled: isCalled))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isWinningCell ? BingoTheme.gold : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(cellText), \(isMarked ? "marked" : "not marked")")
        .accessibilityHint("Double tap to \(isMarked ? "unmark" : "mark") this cell")
    }

    private func getCellText(row: Int, col: Int) -> String {
        guard card.cells.count > row, card.cells[row].count > col else { return "" }
        return card.cells[row][col]
    }

    private func getMarked(row: Int, col: Int) -> Bool {
        let m = card.marked
        guard m.count > row, m[row].count > col else { return false }
        return m[row][col]
    }

    private func cellFontSize(for text: String) -> CGFloat {
        if text == "FREE" { return 12 }
        if text.count <= 3 { return 16 }
        if text.count <= 6 { return 11 }
        return 9
    }

    private func cellBackground(isFree: Bool, isMarked: Bool, isWinningCell: Bool, isCalled: Bool) -> Color {
        if isFree { return BingoTheme.gold }
        if isWinningCell { return BingoTheme.red }
        if isMarked { return BingoTheme.red.opacity(0.8) }
        if isCalled { return BingoTheme.lightNavy.opacity(0.5) }
        return BingoTheme.unmarkedCell
    }

    private func cellTextColor(isFree: Bool, isMarked: Bool, isWinningCell: Bool) -> Color {
        if isFree { return BingoTheme.navy }
        return .white
    }

    private func toggleCell(row: Int, col: Int) {
        let cellText = getCellText(row: row, col: col)
        guard cellText != "FREE", !cellText.isEmpty else { return }

        var m = card.marked
        guard m.count > row, m[row].count > col else { return }
        m[row][col].toggle()
        card.marked = m

        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

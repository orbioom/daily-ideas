import SwiftUI

struct BoardView: View {
    let guesses: [String]
    let rows: [[LetterState]]
    let current: String
    let shakeTrigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cols = WordGame.wordLength
    private let total = WordGame.maxRows

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 6
            let tile = min((geo.size.width - gap * CGFloat(cols - 1)) / CGFloat(cols),
                           (geo.size.height - gap * CGFloat(total - 1)) / CGFloat(total))
            VStack(spacing: gap) {
                ForEach(0..<total, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { col in
                            tileView(row: row, col: col, size: tile)
                        }
                    }
                    .modifier(ShakeEffect(animatableData: row == guesses.count ? CGFloat(shakeTrigger) : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 0.35), value: shakeTrigger)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func tileView(row: Int, col: Int, size: CGFloat) -> some View {
        let isSubmitted = row < guesses.count
        let isCurrent = row == guesses.count
        let letter = letterFor(row: row, col: col, submitted: isSubmitted, current: isCurrent)
        let state: LetterState = isSubmitted ? rows[row][col] : (letter == nil ? .empty : .filled)

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSubmitted ? Theme.stateColor(state) : Theme.tileEmpty)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSubmitted ? .clear : (letter == nil ? Theme.tileBorder : Theme.tileFilledBorder),
                                      lineWidth: 2)
                )
            if let letter {
                Text(String(letter).uppercased())
                    .font(.system(size: size * 0.46, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSubmitted ? .white : Theme.ink)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isCurrent && letter != nil && col == current.count - 1 && !reduceMotion ? 1.05 : 1.0)
        .animation(reduceMotion ? nil : .spring(duration: 0.12), value: current)
        .accessibilityLabel(accessibilityLabel(row: row, col: col, letter: letter, state: state, submitted: isSubmitted))
    }

    private func letterFor(row: Int, col: Int, submitted: Bool, current isCurrent: Bool) -> Character? {
        if submitted {
            let g = Array(guesses[row]); return col < g.count ? g[col] : nil
        } else if isCurrent {
            let c = Array(current); return col < c.count ? c[col] : nil
        }
        return nil
    }

    private func accessibilityLabel(row: Int, col: Int, letter: Character?, state: LetterState, submitted: Bool) -> String {
        guard let letter else { return "empty" }
        if submitted {
            let desc: String
            switch state {
            case .correct: desc = "correct"
            case .present: desc = "wrong place"
            default: desc = "not in word"
            }
            return "\(String(letter).uppercased()), \(desc)"
        }
        return String(letter).uppercased()
    }
}

/// Horizontal shake for invalid submissions.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 8 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

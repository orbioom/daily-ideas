import SwiftUI

struct LetterTile: View {
    let letter: Character?
    let state: LetterState
    var pop: Bool = false   // current-row typed pop
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(state.filled ? state.tint : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(state.filled ? Color.clear :
                            (letter != nil ? Brand.text2 : Brand.hairline), lineWidth: 2)
                )
            if let letter {
                Text(String(letter).uppercased())
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(state.filled ? .white : Brand.text)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(pop && !reduceMotion ? 1.08 : 1)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pop)
        .accessibilityHidden(true)
    }
}

struct GuessRow: View {
    let letters: [Character?]
    let states: [LetterState]
    var shake: Bool = false
    var reveal: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { i in
                LetterTile(letter: letters[safe: i] ?? nil,
                           state: states[safe: i] ?? .empty,
                           pop: (letters[safe: i] ?? nil) != nil && !(states[safe: i]?.filled ?? false))
                    .scaleEffect(reveal && !reduceMotion ? 1 : 1)
                    .opacity(reveal && !reduceMotion ? 1 : 1)
                    .rotation3DEffect(
                        .degrees(reveal && !reduceMotion ? 0 : 0),
                        axis: (x: 1, y: 0, z: 0))
            }
        }
        .offset(x: shake && !reduceMotion ? -8 : 0)
        .animation(shake ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: shake)
        .accessibilityElement()
        .accessibilityLabel(rowAccessibility)
    }

    private var rowAccessibility: String {
        let word = letters.compactMap { $0 }.map { String($0) }.joined()
        if word.isEmpty { return "Empty row" }
        if states.first?.filled == true {
            let parts = zip(letters, states).compactMap { (l, s) -> String? in
                guard let l else { return nil }
                let label: String
                switch s { case .correct: label = "correct"; case .present: label = "present"; default: label = "absent" }
                return "\(l) \(label)"
            }
            return parts.joined(separator: ", ")
        }
        return word
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

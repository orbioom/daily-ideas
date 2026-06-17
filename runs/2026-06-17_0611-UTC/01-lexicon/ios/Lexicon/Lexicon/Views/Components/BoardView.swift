import SwiftUI

/// The grid of tiles: maxGuesses rows × wordLength columns.
/// Reads everything it needs from the GameViewModel; applies a shake to the
/// current row when an invalid entry is rejected.
struct BoardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let vm: GameViewModel
    let highContrast: Bool

    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<vm.maxGuesses, id: \.self) { r in
                row(r)
                    .offset(x: r == vm.currentRow ? shakeOffset : 0)
            }
        }
        .onChange(of: vm.shakeToken) { _, _ in
            triggerShake()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Guess board")
    }

    @ViewBuilder
    private func row(_ r: Int) -> some View {
        let letters = vm.rows[safe: r] ?? []
        let rowStates = vm.states[safe: r] ?? []
        let isSubmittedRow = r < vm.currentRow

        HStack(spacing: 6) {
            ForEach(0..<vm.wordLength, id: \.self) { c in
                let letter = letters[safe: c]
                let state: TileState = {
                    if isSubmittedRow {
                        return rowStates[safe: c] ?? .absent
                    }
                    return letter == nil ? .empty : .tbd
                }()
                TileView(
                    letter: letter,
                    state: state,
                    highContrast: highContrast,
                    revealDelay: isSubmittedRow ? Double(c) * 0.18 : 0
                )
            }
        }
    }

    private func triggerShake() {
        guard !reduceMotion else { return }
        let pattern: [CGFloat] = [-10, 10, -8, 8, -4, 4, 0]
        var delay: Double = 0
        for value in pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.05)) { shakeOffset = value }
            }
            delay += 0.05
        }
    }
}

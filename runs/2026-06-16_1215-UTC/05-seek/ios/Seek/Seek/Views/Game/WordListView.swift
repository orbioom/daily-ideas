import SwiftUI

/// The flowing list of words to find. Found words are struck through and tinted.
struct WordListView: View {
    let words: [String]
    let found: Set<String>
    let highlightColor: Color
    let lastFoundFlash: String?
    let reduceMotion: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(words, id: \.self) { word in
                let isFound = found.contains(word)
                Text(word)
                    .font(Theme.rounded(15, .semibold))
                    .strikethrough(isFound, color: highlightColor)
                    .foregroundStyle(isFound ? highlightColor : Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(isFound ? highlightColor.opacity(0.14) : Theme.surfaceAlt)
                    )
                    .scaleEffect(lastFoundFlash == word && !reduceMotion ? 1.08 : 1)
                    .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: lastFoundFlash)
                    .accessibilityLabel(word)
                    .accessibilityValue(isFound ? "Found" : "Not found")
            }
        }
    }
}

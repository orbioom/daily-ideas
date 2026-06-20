import SwiftUI

struct HuntWordBankView: View {
    let foundWords: [String]
    let lastWordValid: Bool
    let lastWord: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Found Words")
                    .font(.caption)
                    .foregroundStyle(HuntTheme.secondaryText)
                Spacer()
                Text("\(foundWords.count) words")
                    .font(.caption)
                    .foregroundStyle(HuntTheme.secondaryText)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(foundWords.reversed(), id: \.self) { word in
                        WordBadge(word: word)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: foundWords.isEmpty ? 0 : 40)

            // Last word feedback
            if let word = lastWord {
                HStack {
                    Spacer()
                    Text(lastWordValid ? "checkmark \(word.uppercased())" : "\(word.uppercased()) — not valid")
                        .font(.caption.bold())
                        .foregroundStyle(lastWordValid ? HuntTheme.timerNormal : HuntTheme.invalidWord)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer()
                }
                .animation(.easeInOut, value: word)
            }
        }
    }
}

private struct WordBadge: View {
    let word: String

    var body: some View {
        Text(word.uppercased())
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(HuntTheme.validWord)
            .clipShape(Capsule())
    }
}

import SwiftUI

/// Collapsible drawer listing found words, with pangrams highlighted.
struct FoundWordsDrawer: View {
    let words: [String]
    let letterSet: Set<Character>
    @State private var expanded = false

    private var pangrams: Set<String> {
        Set(words.filter { Scoring.isPangram($0, letterSet: letterSet) })
    }

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Text("Found \(words.count)")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(words.count) words found")
            .accessibilityHint(expanded ? "Collapse list" : "Expand list")

            if words.isEmpty {
                Text("No words yet — tap letters and press Enter.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else if expanded {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(words, id: \.self) { word in
                        wordChip(word)
                    }
                }
            } else {
                // Compact horizontal preview of most recent words.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(words.suffix(12).reversed(), id: \.self) { word in
                            wordChip(word)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func wordChip(_ word: String) -> some View {
        let isPangram = pangrams.contains(word)
        Text(word.capitalized)
            .font(Theme.rounded(14, isPangram ? .bold : .medium))
            .foregroundStyle(isPangram ? Color.white : Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isPangram ? Theme.accent : Theme.surfaceAlt)
            )
            .accessibilityLabel(isPangram ? "\(word), pangram" : word)
    }
}

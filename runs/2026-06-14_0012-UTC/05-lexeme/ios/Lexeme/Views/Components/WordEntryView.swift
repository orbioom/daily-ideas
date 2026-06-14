import SwiftUI

/// A full dictionary-style rendering of a word: the headword, POS, tier, definition,
/// example, etymology, and synonym/antonym chips. Reused by Word Detail and the
/// quiz "you missed it" feedback card.
struct WordEntryView: View {
    let word: VocabWord
    var showExample: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Headword
            VStack(alignment: .leading, spacing: 6) {
                Text(word.word)
                    .font(Theme.serif(34, .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 10) {
                    POSTag(pos: word.partOfSpeech)
                    TierBadge(tier: word.tier)
                }
            }

            // Definition
            Text(word.definition)
                .font(Theme.serif(18))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            // Example
            if showExample {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "Example")
                    Text("\u{201C}\(word.example)\u{201D}")
                        .font(Theme.serif(16).italic())
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Synonyms
            if !word.synonyms.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    SectionLabel(text: "Synonyms")
                    ChipFlow(items: word.synonyms, tint: Theme.accent)
                }
            }

            // Antonyms
            if !word.antonyms.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    SectionLabel(text: "Antonyms")
                    ChipFlow(items: word.antonyms, tint: Theme.bad)
                }
            }

            // Etymology
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: "Origin")
                Text(word.etymology)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
